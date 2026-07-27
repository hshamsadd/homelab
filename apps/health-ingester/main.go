package main

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	_ "embed"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

const (
	maxRequestBytes = 10 << 20
	requestTimeout  = 20 * time.Second
)

//go:embed migrations/001_init.sql
var migrationSQL string

//go:embed migrations/002_analytics.sql
var analyticsMigrationSQL string

var (
	requestsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "health_ingester_http_requests_total",
			Help: "HTTP requests handled by route and status.",
		},
		[]string{"route", "method", "status"},
	)
	payloadsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "health_ingester_payloads_total",
			Help: "Webhook payload outcomes.",
		},
		[]string{"result"},
	)
	recordsTotal = prometheus.NewCounterVec(
		prometheus.CounterOpts{
			Name: "health_ingester_records_total",
			Help: "Health records processed, without exposing health values.",
		},
		[]string{"data_type", "result"},
	)
	lastSuccess = prometheus.NewGauge(
		prometheus.GaugeOpts{
			Name: "health_ingester_last_success_unixtime",
			Help: "Unix timestamp of the most recent successful ingestion.",
		},
	)
)

func init() {
	prometheus.MustRegister(requestsTotal, payloadsTotal, recordsTotal, lastSuccess)
}

type config struct {
	ListenAddress       string
	DatabaseHost        string
	DatabasePort        uint16
	DatabaseName        string
	DatabaseUser        string
	DatabasePassword    string
	DatabaseSSLMode     string
	GrafanaDatabaseRole string
	WebhookToken        string
}

func loadConfig() (config, error) {
	port, err := strconv.ParseUint(envOr("DATABASE_PORT", "5432"), 10, 16)
	if err != nil {
		return config{}, fmt.Errorf("DATABASE_PORT: %w", err)
	}

	cfg := config{
		ListenAddress:       envOr("LISTEN_ADDRESS", ":8080"),
		DatabaseHost:        os.Getenv("DATABASE_HOST"),
		DatabasePort:        uint16(port),
		DatabaseName:        os.Getenv("DATABASE_NAME"),
		DatabaseUser:        os.Getenv("DATABASE_USER"),
		DatabasePassword:    os.Getenv("DATABASE_PASSWORD"),
		DatabaseSSLMode:     envOr("DATABASE_SSLMODE", "disable"),
		GrafanaDatabaseRole: os.Getenv("GRAFANA_DATABASE_ROLE"),
		WebhookToken:        os.Getenv("WEBHOOK_TOKEN"),
	}

	required := map[string]string{
		"DATABASE_HOST":         cfg.DatabaseHost,
		"DATABASE_NAME":         cfg.DatabaseName,
		"DATABASE_USER":         cfg.DatabaseUser,
		"DATABASE_PASSWORD":     cfg.DatabasePassword,
		"GRAFANA_DATABASE_ROLE": cfg.GrafanaDatabaseRole,
		"WEBHOOK_TOKEN":         cfg.WebhookToken,
	}
	for name, value := range required {
		if strings.TrimSpace(value) == "" {
			return config{}, fmt.Errorf("%s is required", name)
		}
	}

	return cfg, nil
}

func envOr(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

type parsedRecord struct {
	DataType   string
	StartTime  *time.Time
	EndTime    *time.Time
	ObservedAt *time.Time
	Hash       []byte
	Data       []byte
}

type parsedPayload struct {
	Timestamp  time.Time
	AppVersion string
	Hash       []byte
	Raw        []byte
	Records    []parsedRecord
}

type ingestResult struct {
	BatchID        int64 `json:"batch_id"`
	Received       int   `json:"received"`
	Inserted       int   `json:"inserted"`
	Duplicates     int   `json:"duplicates"`
	DuplicateBatch bool  `json:"duplicate_batch,omitempty"`
}

type store interface {
	Ingest(context.Context, parsedPayload) (ingestResult, error)
	Ping(context.Context) error
	Close()
}

type postgresStore struct {
	pool        *pgxpool.Pool
	database    string
	grafanaRole string
}

func newPostgresStore(ctx context.Context, cfg config) (*postgresStore, error) {
	dsn := (&url.URL{
		Scheme: "postgres",
		User:   url.UserPassword(cfg.DatabaseUser, cfg.DatabasePassword),
		Host:   net.JoinHostPort(cfg.DatabaseHost, strconv.Itoa(int(cfg.DatabasePort))),
		Path:   cfg.DatabaseName,
		RawQuery: url.Values{
			"sslmode": []string{cfg.DatabaseSSLMode},
		}.Encode(),
	}).String()

	poolCfg, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("parse database configuration: %w", err)
	}
	poolCfg.MaxConns = 10
	poolCfg.MinConns = 1
	poolCfg.MaxConnLifetime = 30 * time.Minute
	poolCfg.MaxConnIdleTime = 5 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, poolCfg)
	if err != nil {
		return nil, fmt.Errorf("create database pool: %w", err)
	}

	s := &postgresStore{
		pool:        pool,
		database:    cfg.DatabaseName,
		grafanaRole: cfg.GrafanaDatabaseRole,
	}

	if err := s.waitForDatabase(ctx, time.Minute); err != nil {
		pool.Close()
		return nil, err
	}
	if err := s.migrate(ctx); err != nil {
		pool.Close()
		return nil, err
	}

	return s, nil
}

func (s *postgresStore) waitForDatabase(ctx context.Context, timeout time.Duration) error {
	deadline := time.Now().Add(timeout)
	for {
		pingCtx, cancel := context.WithTimeout(ctx, 3*time.Second)
		err := s.pool.Ping(pingCtx)
		cancel()
		if err == nil {
			return nil
		}
		if time.Now().After(deadline) {
			return fmt.Errorf("database unavailable after %s: %w", timeout, err)
		}
		select {
		case <-ctx.Done():
			return ctx.Err()
		case <-time.After(2 * time.Second):
		}
	}
}

func (s *postgresStore) migrate(ctx context.Context) error {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return fmt.Errorf("begin migration: %w", err)
	}
	defer tx.Rollback(ctx)

	migrations := []struct {
		name string
		sql  string
	}{
		{name: "001_init", sql: migrationSQL},
		{name: "002_analytics", sql: analyticsMigrationSQL},
	}
	for _, migration := range migrations {
		if _, err := tx.Exec(ctx, migration.sql); err != nil {
			return fmt.Errorf("apply migration %s: %w", migration.name, err)
		}
	}

	db := pgx.Identifier{s.database}.Sanitize()
	role := pgx.Identifier{s.grafanaRole}.Sanitize()
	grants := fmt.Sprintf(`
		GRANT CONNECT ON DATABASE %s TO %s;
		GRANT USAGE ON SCHEMA health TO %s;
		GRANT SELECT ON ALL TABLES IN SCHEMA health TO %s;
		ALTER DEFAULT PRIVILEGES IN SCHEMA health GRANT SELECT ON TABLES TO %s;
	`, db, role, role, role, role)
	if _, err := tx.Exec(ctx, grants); err != nil {
		return fmt.Errorf("apply Grafana grants: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return fmt.Errorf("commit migration: %w", err)
	}
	return nil
}

func (s *postgresStore) Ingest(ctx context.Context, payload parsedPayload) (ingestResult, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return ingestResult{}, err
	}
	defer tx.Rollback(ctx)

	var batchID int64
	result := ingestResult{}
	err = tx.QueryRow(
		ctx,
		`INSERT INTO health.ingest_batches
			(source_timestamp, app_version, payload_hash, received_records, raw_payload)
		 VALUES ($1, $2, $3, $4, $5)
		 ON CONFLICT (payload_hash) DO NOTHING
		 RETURNING id`,
		payload.Timestamp,
		payload.AppVersion,
		payload.Hash,
		len(payload.Records),
		string(payload.Raw),
	).Scan(&batchID)
	if errors.Is(err, pgx.ErrNoRows) {
		err = tx.QueryRow(
			ctx,
			`SELECT id, received_records, inserted_records, duplicate_records
			 FROM health.ingest_batches
			 WHERE payload_hash = $1`,
			payload.Hash,
		).Scan(
			&result.BatchID,
			&result.Received,
			&result.Inserted,
			&result.Duplicates,
		)
		if err != nil {
			return ingestResult{}, fmt.Errorf("read duplicate batch: %w", err)
		}
		if err := tx.Commit(ctx); err != nil {
			return ingestResult{}, err
		}
		result.DuplicateBatch = true
		return result, nil
	}
	if err != nil {
		return ingestResult{}, fmt.Errorf("insert batch: %w", err)
	}

	result = ingestResult{
		BatchID:  batchID,
		Received: len(payload.Records),
	}
	for _, record := range payload.Records {
		tag, err := tx.Exec(
			ctx,
			`INSERT INTO health.records
				(batch_id, data_type, start_time, end_time, observed_at, record_hash, data)
			 VALUES ($1, $2, $3, $4, $5, $6, $7)
			 ON CONFLICT (record_hash) DO NOTHING`,
			batchID,
			record.DataType,
			record.StartTime,
			record.EndTime,
			record.ObservedAt,
			record.Hash,
			string(record.Data),
		)
		if err != nil {
			return ingestResult{}, fmt.Errorf("insert %s record: %w", record.DataType, err)
		}
		label := metricDataType(record.DataType)
		if tag.RowsAffected() == 1 {
			result.Inserted++
			recordsTotal.WithLabelValues(label, "inserted").Inc()
		} else {
			result.Duplicates++
			recordsTotal.WithLabelValues(label, "duplicate").Inc()
		}
	}

	_, err = tx.Exec(
		ctx,
		`UPDATE health.ingest_batches
		 SET inserted_records = $2, duplicate_records = $3
		 WHERE id = $1`,
		batchID,
		result.Inserted,
		result.Duplicates,
	)
	if err != nil {
		return ingestResult{}, fmt.Errorf("update batch counts: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return ingestResult{}, err
	}
	return result, nil
}

func (s *postgresStore) Ping(ctx context.Context) error {
	return s.pool.Ping(ctx)
}

func (s *postgresStore) Close() {
	s.pool.Close()
}

type api struct {
	store     store
	tokenHash [sha256.Size]byte
	logger    *slog.Logger
}

func newAPI(s store, token string, logger *slog.Logger) *api {
	return &api{
		store:     s,
		tokenHash: sha256.Sum256([]byte(token)),
		logger:    logger,
	}
}

func (a *api) routes() http.Handler {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", a.health)
	mux.HandleFunc("GET /readyz", a.ready)
	mux.Handle("GET /metrics", promhttp.Handler())
	mux.HandleFunc("POST /v1/health-connect", a.ingest)
	return securityHeaders(mux)
}

func (a *api) health(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (a *api) ready(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
	defer cancel()
	if err := a.store.Ping(ctx); err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"status": "unavailable"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ready"})
}

func (a *api) ingest(w http.ResponseWriter, r *http.Request) {
	status := http.StatusInternalServerError
	defer func() {
		requestsTotal.WithLabelValues("/v1/health-connect", r.Method, strconv.Itoa(status)).Inc()
	}()

	if !a.authorized(r.Header.Get("Authorization")) {
		status = http.StatusUnauthorized
		payloadsTotal.WithLabelValues("unauthorized").Inc()
		writeJSON(w, status, map[string]string{"status": "unauthorized"})
		return
	}

	r.Body = http.MaxBytesReader(w, r.Body, maxRequestBytes)
	raw, err := io.ReadAll(r.Body)
	if err != nil {
		status = http.StatusRequestEntityTooLarge
		payloadsTotal.WithLabelValues("invalid").Inc()
		writeJSON(w, status, map[string]string{"status": "invalid_request"})
		return
	}

	payload, err := parsePayload(raw)
	if err != nil {
		status = http.StatusBadRequest
		payloadsTotal.WithLabelValues("invalid").Inc()
		writeJSON(w, status, map[string]string{"status": "invalid_payload"})
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), requestTimeout)
	defer cancel()
	result, err := a.store.Ingest(ctx, payload)
	if err != nil {
		a.logger.Error("ingestion failed", "error", err)
		status = http.StatusInternalServerError
		payloadsTotal.WithLabelValues("error").Inc()
		writeJSON(w, status, map[string]string{"status": "error"})
		return
	}

	status = http.StatusOK
	payloadsTotal.WithLabelValues("success").Inc()
	lastSuccess.SetToCurrentTime()
	writeJSON(w, status, struct {
		Status string `json:"status"`
		ingestResult
	}{
		Status:       "ok",
		ingestResult: result,
	})
	a.logger.Info(
		"health payload accepted",
		"batch_id", result.BatchID,
		"received", result.Received,
		"inserted", result.Inserted,
		"duplicates", result.Duplicates,
		"app_version", payload.AppVersion,
	)
}

func (a *api) authorized(header string) bool {
	const prefix = "Bearer "
	if !strings.HasPrefix(header, prefix) {
		return false
	}
	actual := sha256.Sum256([]byte(strings.TrimSpace(strings.TrimPrefix(header, prefix))))
	return subtle.ConstantTimeCompare(actual[:], a.tokenHash[:]) == 1
}

func parsePayload(raw []byte) (parsedPayload, error) {
	var root map[string]json.RawMessage
	if err := json.Unmarshal(raw, &root); err != nil {
		return parsedPayload{}, err
	}

	var timestampString string
	if err := json.Unmarshal(root["timestamp"], &timestampString); err != nil {
		return parsedPayload{}, errors.New("timestamp is required")
	}
	timestamp, err := time.Parse(time.RFC3339Nano, timestampString)
	if err != nil {
		return parsedPayload{}, errors.New("timestamp must be RFC3339")
	}

	var appVersion string
	if err := json.Unmarshal(root["app_version"], &appVersion); err != nil || strings.TrimSpace(appVersion) == "" {
		return parsedPayload{}, errors.New("app_version is required")
	}

	canonical, err := json.Marshal(root)
	if err != nil {
		return parsedPayload{}, err
	}
	payloadHash := sha256.Sum256(canonical)

	result := parsedPayload{
		Timestamp:  timestamp,
		AppVersion: appVersion,
		Hash:       payloadHash[:],
		Raw:        canonical,
	}

	for dataType, value := range root {
		if dataType == "timestamp" || dataType == "app_version" {
			continue
		}

		var records []json.RawMessage
		if err := json.Unmarshal(value, &records); err != nil {
			continue
		}
		for _, rawRecord := range records {
			var object map[string]json.RawMessage
			if err := json.Unmarshal(rawRecord, &object); err != nil {
				return parsedPayload{}, fmt.Errorf("%s contains a non-object record", dataType)
			}
			recordJSON, err := json.Marshal(object)
			if err != nil {
				return parsedPayload{}, err
			}
			recordHash := sha256.Sum256(append([]byte(dataType+"\x00"), recordJSON...))
			result.Records = append(result.Records, parsedRecord{
				DataType:  dataType,
				StartTime: parseTimeField(object, "start_time"),
				EndTime:   parseTimeField(object, "end_time"),
				ObservedAt: firstTime(
					parseTimeField(object, "time"),
					parseTimeField(object, "session_end_time"),
					parseTimeField(object, "end_time"),
				),
				Hash: recordHash[:],
				Data: recordJSON,
			})
		}
	}

	return result, nil
}

func parseTimeField(object map[string]json.RawMessage, field string) *time.Time {
	raw, ok := object[field]
	if !ok {
		return nil
	}
	var value string
	if err := json.Unmarshal(raw, &value); err != nil {
		return nil
	}
	parsed, err := time.Parse(time.RFC3339Nano, value)
	if err != nil {
		return nil
	}
	return &parsed
}

func firstTime(values ...*time.Time) *time.Time {
	for _, value := range values {
		if value != nil {
			return value
		}
	}
	return nil
}

func metricDataType(dataType string) string {
	switch dataType {
	case "steps", "sleep", "heart_rate", "heart_rate_variability",
		"distance", "active_calories", "total_calories", "weight", "height",
		"blood_pressure", "blood_glucose", "oxygen_saturation",
		"body_temperature", "skin_temperature", "respiratory_rate",
		"resting_heart_rate", "exercise", "hydration", "nutrition",
		"basal_metabolic_rate", "body_fat", "lean_body_mass", "vo2_max",
		"bone_mass", "menstruation_flow", "menstruation_period",
		"intermenstrual_bleeding", "ovulation_test", "cervical_mucus",
		"sexual_activity", "basal_body_temperature":
		return dataType
	default:
		return "unknown"
	}
}

func securityHeaders(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("X-Content-Type-Options", "nosniff")
		w.Header().Set("X-Frame-Options", "DENY")
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	cfg, err := loadConfig()
	if err != nil {
		logger.Error("configuration error", "error", err)
		os.Exit(1)
	}

	rootCtx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	db, err := newPostgresStore(rootCtx, cfg)
	if err != nil {
		logger.Error("database initialization failed", "error", err)
		os.Exit(1)
	}
	defer db.Close()

	server := &http.Server{
		Addr:              cfg.ListenAddress,
		Handler:           newAPI(db, cfg.WebhookToken, logger).routes(),
		ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      30 * time.Second,
		IdleTimeout:       60 * time.Second,
		MaxHeaderBytes:    16 << 10,
	}

	go func() {
		<-rootCtx.Done()
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = server.Shutdown(shutdownCtx)
	}()

	logger.Info("health ingester listening", "address", cfg.ListenAddress)
	if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
		logger.Error("HTTP server failed", "error", err)
		os.Exit(1)
	}
}
