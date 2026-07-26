# syntax=docker/dockerfile:1.7

FROM --platform=$BUILDPLATFORM golang:1.24-alpine AS build

ARG TARGETOS
ARG TARGETARCH

WORKDIR /src

COPY go.mod ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -o /out/health-ingester .

FROM scratch

USER 65532:65532
COPY --from=build /out/health-ingester /health-ingester

EXPOSE 8080

ENTRYPOINT ["/health-ingester"]
