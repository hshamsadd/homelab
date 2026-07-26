package main

import (
	"context"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type fakeStore struct {
	result ingestResult
	err    error
	got    parsedPayload
}

func (f *fakeStore) Ingest(_ context.Context, payload parsedPayload) (ingestResult, error) {
	f.got = payload
	return f.result, f.err
}

func (f *fakeStore) Ping(context.Context) error { return f.err }
func (f *fakeStore) Close()                     {}

func TestParsePayloadSupportsKnownAndFutureTypes(t *testing.T) {
	payload, err := parsePayload([]byte(`{
		"timestamp":"2026-07-26T20:00:00Z",
		"app_version":"1.9.15",
		"steps":[{"count":321,"start_time":"2026-07-26T19:00:00Z","end_time":"2026-07-26T19:20:00Z"}],
		"future_metric":[{"value":12,"time":"2026-07-26T19:30:00Z"}]
	}`))
	if err != nil {
		t.Fatalf("parsePayload: %v", err)
	}
	if len(payload.Records) != 2 {
		t.Fatalf("records = %d, want 2", len(payload.Records))
	}
	if payload.AppVersion != "1.9.15" {
		t.Fatalf("app version = %q", payload.AppVersion)
	}
}

func TestRecordHashIsStable(t *testing.T) {
	first, err := parsePayload([]byte(`{
		"timestamp":"2026-07-26T20:00:00Z",
		"app_version":"1.9.15",
		"steps":[{"count":321,"start_time":"2026-07-26T19:00:00Z","end_time":"2026-07-26T19:20:00Z"}]
	}`))
	if err != nil {
		t.Fatal(err)
	}
	second, err := parsePayload([]byte(`{
		"app_version":"1.9.15",
		"steps":[{"end_time":"2026-07-26T19:20:00Z","count":321,"start_time":"2026-07-26T19:00:00Z"}],
		"timestamp":"2026-07-26T20:01:00Z"
	}`))
	if err != nil {
		t.Fatal(err)
	}
	if string(first.Records[0].Hash) != string(second.Records[0].Hash) {
		t.Fatal("equivalent records produced different hashes")
	}
}

func TestWebhookRequiresBearerToken(t *testing.T) {
	s := &fakeStore{}
	handler := newAPI(s, "expected-token", slog.New(slog.NewTextHandler(io.Discard, nil))).routes()
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/health-connect",
		strings.NewReader(`{"timestamp":"2026-07-26T20:00:00Z","app_version":"1.9.15"}`),
	)
	response := httptest.NewRecorder()

	handler.ServeHTTP(response, request)

	if response.Code != http.StatusUnauthorized {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusUnauthorized)
	}
}

func TestWebhookAcceptsDocumentedPayload(t *testing.T) {
	s := &fakeStore{
		result: ingestResult{BatchID: 7, Received: 1, Inserted: 1},
	}
	handler := newAPI(s, "expected-token", slog.New(slog.NewTextHandler(io.Discard, nil))).routes()
	request := httptest.NewRequest(
		http.MethodPost,
		"/v1/health-connect",
		strings.NewReader(`{
			"timestamp":"2026-07-26T20:00:00Z",
			"app_version":"1.9.15",
			"steps":[{"count":321,"start_time":"2026-07-26T19:00:00Z","end_time":"2026-07-26T19:20:00Z"}]
		}`),
	)
	request.Header.Set("Authorization", "Bearer expected-token")
	response := httptest.NewRecorder()

	handler.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
	if len(s.got.Records) != 1 || s.got.Records[0].DataType != "steps" {
		t.Fatalf("stored records = %#v", s.got.Records)
	}
}
