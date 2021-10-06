FROM golang:1.16-alpine AS builder

WORKDIR /app

COPY go.* ./
RUN go mod download

COPY main.go main.go

RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o=consumer


FROM scratch AS runner

COPY --from=builder /app/consumer /consumer

ENTRYPOINT ["/consumer"]
CMD []
