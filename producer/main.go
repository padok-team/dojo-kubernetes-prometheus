package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/go-redis/redis/v8"
	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

// =============================================================================
// CLI flags
// =============================================================================

var (
	httpAddr   = flag.String("http", ":8080", "Address to listen for requests on")
	redisAddr  = flag.String("redis-server", "redis-master:6379", "Redis server to publish messages to")
	redisQueue = flag.String("redis-queue", "padok", "Redis queue to publish messages to")
)

// =============================================================================
// Main logic
// =============================================================================

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	flag.Parse()

	client := redis.NewClient(&redis.Options{
		Addr: *redisAddr,
	})

	p := newProducer(client, *redisQueue)

	log.Printf("Listening on %s...", *httpAddr)
	if err := http.ListenAndServe(*httpAddr, p.router); err != nil {
		return fmt.Errorf("unable to listen for requests: %w", err)
	}

	return nil
}

// =============================================================================
// HTTP server
// =============================================================================

type producer struct {
	router *mux.Router

	client  *redis.Client
	queue   string
	counter int

	healthy bool

	published prometheus.Counter
}

func newProducer(client *redis.Client, queue string) *producer {
	p := producer{
		router:  mux.NewRouter(),
		client:  client,
		queue:   queue,
		healthy: true,
		published: promauto.NewCounter(prometheus.CounterOpts{
			Name: "producer_messages_published_total",
			Help: "The total number of published messages",
		}),
	}

	p.router.Handle("/publish", handlers.LoggingHandler(os.Stdout, http.HandlerFunc(p.handlePublish))).Methods("POST")
	p.router.Handle("/publish/{count:[0-9]+}", handlers.LoggingHandler(os.Stdout, http.HandlerFunc(p.handlePublishMany))).Methods("POST")
	p.router.HandleFunc("/healthz", p.handleHealthcheck).Methods("GET")
	p.router.Handle("/metrics", promhttp.Handler())

	return &p
}

// =============================================================================
// HTTP handlers
// =============================================================================

func (p *producer) handlePublish(w http.ResponseWriter, r *http.Request) {
	if err := p.publish(r.Context()); err != nil {
		http.Error(w, fmt.Sprintf("An error occured: %s", err.Error()), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "Message published 👌\n")
}

func (p *producer) handlePublishMany(w http.ResponseWriter, r *http.Request) {
	requestVars := mux.Vars(r)
	rawCount, ok := requestVars["count"]
	if !ok {
		http.Error(w, "Missing number of messages to publish", http.StatusBadRequest)
	}
	count, err := strconv.Atoi(rawCount)
	if err != nil {
		http.Error(w, fmt.Sprintf("Invalid number of messages to publish: %q", rawCount), http.StatusBadRequest)
	}

	if err := p.publishMany(r.Context(), count); err != nil {
		http.Error(w, fmt.Sprintf("An error occured: %s", err.Error()), http.StatusInternalServerError)
		return
	}

	fmt.Fprintf(w, "%d messages published 👌\n", count)
}

func (p *producer) handleHealthcheck(w http.ResponseWriter, r *http.Request) {
	switch p.healthy {
	case true:
		fmt.Fprintf(w, "The server is healthy")
	case false:
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "The server is unhealthy: the last attempt to publish a message failed")
	}
}

// =============================================================================
// Message publishing
// =============================================================================

func (p *producer) publish(ctx context.Context) error {
	if err := p.client.RPush(ctx, p.queue, "From Padok, with love 💜").Err(); err != nil {
		p.healthy = false
		return fmt.Errorf("failed to publish: %w", err)
	}
	p.published.Inc()
	p.healthy = true
	return nil
}

func (p *producer) publishMany(ctx context.Context, count int) error {
	for i := 0; i < count; i++ {
		if err := p.publish(ctx); err != nil {
			return fmt.Errorf("only %d of %d messages published: %w", i, count, err)
		}
	}
	return nil
}
