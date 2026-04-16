from flask import Flask, jsonify, Response
import time
import random

from prometheus_client import (
    Counter,
    Histogram,
    Gauge,
    generate_latest,
    CONTENT_TYPE_LATEST
)

# ----------------------------
# Flask app MUST be defined first
# ----------------------------
app = Flask(__name__)

# ----------------------------
# Prometheus Metrics
# ----------------------------

# Counter: total HTTP requests
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)

# Histogram: request latency
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
    buckets=[0.01, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5],
)

# Business metrics
PAYMENT_SUCCESS = Counter("payment_success_total", "Successful payments")
PAYMENT_FAILURE = Counter("payment_failure_total", "Failed payments")

# App health metric
APP_UP = Gauge("pay_api_up", "Whether pay-api is running")
APP_UP.set(1)

# ----------------------------
# Routes
# ----------------------------

@app.route("/")
def home():
    return "Pay API is running"

@app.route("/payment")
def payment():
    start = time.time()

    delay = random.uniform(0.05, 0.5)
    time.sleep(delay)

    if random.random() < 0.05:  # 5% failure rate
        PAYMENT_FAILURE.inc()
        REQUEST_COUNT.labels(
            method="GET",
            endpoint="/payment",
            status="500"
        ).inc()

        return jsonify({"status": "error"}), 500

    PAYMENT_SUCCESS.inc()
    REQUEST_COUNT.labels(
        method="GET",
        endpoint="/payment",
        status="200"
    ).inc()

    REQUEST_LATENCY.labels(
        method="GET",
        endpoint="/payment"
    ).observe(time.time() - start)

    return jsonify({"status": "success"})


@app.route("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)
