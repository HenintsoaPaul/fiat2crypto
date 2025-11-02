# Fiat2Crypto Gateway — README

> **One-liner:** A secure, compliant payments on-ramp & payout platform connecting fiat rails to crypto wallets with real-time fraud scoring.

---

## Table of Contents

1. Project overview
2. Goals & MVP scope
3. High-level architecture
4. Folder structure (LLM-friendly)
5. Sample Dockerfiles (API Gateway, Payment Orchestrator (Go), Auth (Spring Boot), Fraud Scorer (Spark))
6. Helm chart skeleton (single chart for MVP)
7. Minimal Terraform + Kubernetes manifests for MVP
8. CI/CD notes (GitHub Actions + ArgoCD example snippets)
9. Security checklist & notes
10. Runbook & local dev instructions
11. Agile implementation schedule (sprint plan)
12. Helpful commands & templates

---

## 1. Project overview

Fiat2Crypto Gateway is a modular microservice platform that lets merchants and users move fiat into/out of crypto wallets while enforcing AML/fraud scoring, reconciliation, and auditability. The MVP targets the core flow: authenticated payment initiation → orchestrated payment connector → ledger event → fraud scoring → notification + basic reconciliation.

The project emphasizes: event-driven design (Kafka), resilient connectors (Go), enterprise services (Spring Boot), real-time + batch analytics (Spark + HDFS), and deployability (Docker + Kubernetes + Terraform).

---

## 2. Goals & MVP scope

**MVP features (prioritized):**

* OAuth2-based authentication service
* API Gateway exposing merchant endpoints
* Payment Orchestrator (Go) with a mock bank connector
* Ledger service (Postgres) with event-sourced transaction writes
* Kafka local cluster for event streaming (dev) and topics: `transactions.raw`, `transactions.scored`, `wallet.events`
* Fraud Scorer: Spark Structured Streaming job that consumes `transactions.raw` and writes `transactions.scored` (simple rule-based model in MVP)
* Notification service (webhook + simple push) for payment updates
* Flutter minimal mobile client for demo (initiate payment, view status)
* Angular/Vue admin dashboard to view transactions and fraud queue

**Out of scope for MVP:** real bank/card integrations, on-chain transfers, HSM integration (use Vault), production-grade Kafka cluster.

---

## 3. High-level architecture

* API Gateway (Spring Boot / Spring Cloud Gateway)
* Auth Service (Spring Boot, Spring Security, OAuth2)
* Payment Orchestrator (Go) — orchestration, retries, publish `transactions.raw` to Kafka
* Ledger Service (Spring Boot) — event-sourced ledger, writes canonical transactions to Postgres
* Kafka cluster (local/dev: embeddable or Redpanda/Strimzi Helm chart)
* Fraud Scorer (Spark Structured Streaming, packaged as container) — consumes `transactions.raw`, emits `transactions.scored`
* Notification Service (Spring Boot) — consumes `transactions.scored` and sends webhooks/push
* Admin Dashboard (Vue.js) — reads from ClickHouse or direct API
* Flutter Mobile App — a demo client

**Data flow** (MVP):

1. Mobile or merchant posts /payments to API Gateway.
2. Gateway authenticates via Auth Service, forwards to Payment Orchestrator.
3. Orchestrator validates and emits `transactions.raw` to Kafka.
4. Fraud Scorer consumes `transactions.raw` and publishes `transactions.scored` with a risk score.
5. Ledger Service consumes `transactions.scored` (or a separate `ledger.commands`) and persists the transaction/event.
6. Notification Service informs the client and admin dashboard.
7. Reconciliation job (Kubernetes CronJob) runs nightly comparing ledger vs `settlement.events` (MVP: simple parity check).

---

## 4. Folder structure (LLM-friendly)

Use this root layout for the repo. Names are intentionally short and machine/LLM friendly.

```
fiat2crypto-gateway/
├─ README.md
├─ infra/
│  ├─ helm/                 # Helm chart skeleton
│  ├─ k8s/                  # Kubernetes manifests
│  └─ terraform/            # Terraform to provision k8s namespace + resources
├─ services/
│  ├─ api-gateway/          # Spring Boot - gateway
│  │  ├─ src/
│  │  ├─ Dockerfile
│  │  └─ helm-values.yaml
│  ├─ auth-service/         # Spring Boot - OAuth2
│  ├─ ledger-service/       # Spring Boot - ledger & audit
│  ├─ payment-orchestrator/ # Golang - orchestration & connectors
│  │  ├─ cmd/
│  │  ├─ internal/
│  │  └─ Dockerfile
│  ├─ notification/         # Spring Boot
│  └─ fraud-scorer/         # Spark job packaged in Docker
├─ frontend/
│  ├─ mobile/               # Flutter app (demo)
│  └─ admin/                # Vue.js/Angular dashboard
├─ infra-scripts/           # scripts for deploying infra locally (kind/k3d)
└─ docs/
   ├─ architecture.md
   └─ runbook.md
```

**Notes:** Keep each service with a `Dockerfile`, `deployment.yaml` and `service.yaml` under `infra/k8s/` for quick deployments.

---

## 5. Sample Dockerfiles

These are minimal, secure Dockerfiles for building each service container. Use multi-stage builds.

### 5.1 API Gateway (Spring Boot)

`services/api-gateway/Dockerfile`

```dockerfile
# Build
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .
COPY src src
RUN ./mvnw -q -DskipTests package

# Run
FROM eclipse-temurin:17-jre-alpine
ARG JAR_FILE=target/*.jar
COPY --from=build /app/${JAR_FILE} /app/app.jar
EXPOSE 8080
ENTRYPOINT ["java","-XX:+UseG1GC","-jar","/app/app.jar"]
```

### 5.2 Payment Orchestrator (Golang)

`services/payment-orchestrator/Dockerfile`

```dockerfile
# Build
FROM golang:1.21-alpine AS build
WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags='-s -w' -o /out/orchestrator ./cmd/orchestrator

# Run
FROM alpine:3.18
RUN apk add --no-cache ca-certificates
COPY --from=build /out/orchestrator /usr/local/bin/orchestrator
EXPOSE 9000
ENTRYPOINT ["/usr/local/bin/orchestrator"]
```

### 5.3 Auth Service (Spring Boot)

Same pattern as API Gateway; change exposed port if needed.

### 5.4 Fraud Scorer (Spark job)

We will run Spark in cluster mode against a Spark on K8s. Use a small image that contains the jar and an entrypoint that launches `spark-submit`.

`services/fraud-scorer/Dockerfile`

```dockerfile
FROM openjdk:17-jre-slim AS build
WORKDIR /app
COPY target/fraud-scorer-*.jar /app/fraud-scorer.jar

FROM bitnami/spark:3.4.0
COPY --from=build /app/fraud-scorer.jar /opt/spark/app/fraud-scorer.jar
WORKDIR /opt/spark/app
ENTRYPOINT ["/opt/bitnami/scripts/spark/entrypoint.sh"]
# The actual spark-submit will be invoked by the k8s job or helm chart with proper args
```

---

## 6. Helm chart skeleton (single umbrella chart for MVP)

Place under `infra/helm/fiat2crypto/`.

```
infra/helm/fiat2crypto/
├─ Chart.yaml
├─ values.yaml
└─ templates/
   ├─ deployment-api-gateway.yaml
   ├─ service-api-gateway.yaml
   ├─ deployment-payment-orch.yaml
   ├─ service-payment-orch.yaml
   ├─ deployment-auth.yaml
   ├─ service-auth.yaml
   └─ NOTES.txt
```

### Chart.yaml

```yaml
apiVersion: v2
name: fiat2crypto
description: Fiat2Crypto Gateway - MVP
version: 0.1.0
appVersion: "0.1.0"
```

### values.yaml (abridged)

```yaml
replicaCount: 1
image:
  repository: your-registry/fiat2crypto
  tag: latest

apiGateway:
  image: "{{ .Values.image.repository }}-api-gateway:{{ .Values.image.tag }}"
  port: 8080

paymentOrch:
  image: "{{ .Values.image.repository }}-payment-orch:{{ .Values.image.tag }}"
  port: 9000

authService:
  image: "{{ .Values.image.repository }}-auth:{{ .Values.image.tag }}"
  port: 8081

kafka:
  enabled: false # recommend using Strimzi or external
```

### templates/deployment-api-gateway.yaml (abridged)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "fiat2crypto.fullname" . }}-api-gateway
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
        - name: api-gateway
          image: {{ .Values.apiGateway.image }}
          ports:
            - containerPort: {{ .Values.apiGateway.port }}
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: "k8s"
```

(Repeat similar templates for other services.)

---

## 7. Minimal Terraform + Kubernetes manifests for MVP

This Terraform uses the Kubernetes provider to create a namespace and apply a couple of base resources. It assumes you already have a kubeconfig (local kind/k3d or cloud cluster).

**Note:** Terraform will not install Kafka. For local/dev, use `k3d` + `helm install strimzi` or use Redpanda. For MVP run `docker-compose` Kafka or use `confluentinc/cp-kafka` images.

`infra/terraform/main.tf`

```hcl
terraform {
  required_providers {
    kubernetes = { source = "hashicorp/kubernetes" }
  }
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

variable "kubeconfig_path" {
  type    = string
  default = "~/.kube/config"
}

resource "kubernetes_namespace" "fiat2crypto" {
  metadata {
    name = "fiat2crypto"
    labels = {
      owner = "fiat2crypto"
    }
  }
}

# Example: apply a deployment manifest for api-gateway
resource "kubernetes_manifest" "api_gateway" {
  manifest = yamldecode(file("${path.module}/k8s/api-gateway-deployment.yaml"))
  depends_on = [kubernetes_namespace.fiat2crypto]
}

resource "kubernetes_manifest" "payment_orch" {
  manifest = yamldecode(file("${path.module}/k8s/payment-orch-deployment.yaml"))
  depends_on = [kubernetes_namespace.fiat2crypto]
}
```

> **Files referenced above**: place k8s manifests in `infra/terraform/k8s/` or `infra/k8s/`.

### `infra/terraform/k8s/api-gateway-deployment.yaml` (simple)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-gateway
  namespace: fiat2crypto
spec:
  replicas: 1
  selector:
    matchLabels:
      app: api-gateway
  template:
    metadata:
      labels:
        app: api-gateway
    spec:
      containers:
        - name: api-gateway
          image: your-registry/fiat2crypto-api-gateway:latest
          ports:
            - containerPort: 8080
          env:
            - name: SPRING_PROFILES_ACTIVE
              value: "k8s"
---
apiVersion: v1
kind: Service
metadata:
  name: api-gateway
  namespace: fiat2crypto
spec:
  selector:
    app: api-gateway
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: ClusterIP
```

### `infra/terraform/k8s/payment-orch-deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-orch
  namespace: fiat2crypto
spec:
  replicas: 1
  selector:
    matchLabels:
      app: payment-orch
  template:
    metadata:
      labels:
        app: payment-orch
    spec:
      containers:
        - name: payment-orch
          image: your-registry/fiat2crypto-payment-orch:latest
          ports:
            - containerPort: 9000
          env:
            - name: KAFKA_BOOTSTRAP_SERVERS
              value: "kafka:9092"
---
apiVersion: v1
kind: Service
metadata:
  name: payment-orch
  namespace: fiat2crypto
spec:
  selector:
    app: payment-orch
  ports:
    - protocol: TCP
      port: 9000
      targetPort: 9000
  type: ClusterIP
```

**How to apply locally (dev):**

1. `kubectl create namespace fiat2crypto` or `terraform init && terraform apply`.
2. Deploy Kafka locally using Helm: `helm repo add strimzi https://strimzi.io/charts/ && helm install my-kafka strimzi/strimzi-kafka-operator -n kafka` (or use Redpanda).
3. `kubectl apply -f infra/terraform/k8s/api-gateway-deployment.yaml` etc.

---

## 8. CI/CD notes (GitHub Actions + ArgoCD)

* **Build & push images**: GitHub Actions workflows building Docker images and pushing to registry on `main`.
* **Helm chart package + push**: package helm and publish to artifact registry or keep charts in repo for ArgoCD.
* **ArgoCD**: watch `infra/helm/fiat2crypto` in the `prod` or `staging` k8s cluster and perform sync.

Example GH Action (build & push) snippet:

```yaml
name: CI
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '17' }
      - name: Build API
        run: |
          cd services/api-gateway
          ./mvnw -DskipTests package
      - name: Build Docker images
        run: |
          docker build -t ${{ secrets.REGISTRY }}/fiat2crypto-api-gateway:latest ./services/api-gateway
          docker push ${{ secrets.REGISTRY }}/fiat2crypto-api-gateway:latest
```

---

## 9. Security checklist & notes

* Use OAuth2 (Authorization Code + PKCE for mobile). Use short-lived JWTs.
* Use mTLS between services or enable Kubernetes Network Policies and a Service Mesh (Istio/Linkerd) for mTLS.
* Store secrets in HashiCorp Vault or Kubernetes External Secrets.
* Encrypt data at rest (Postgres, HDFS) and in transit (TLS everywhere).
* Use input validation, schema validation (Avro with Schema Registry) for Kafka messages.
* Implement idempotency keys at API boundary.
* Do not store PAN/CVV. If card data required, use PCI-compliant tokenization/provider.

---

## 10. Runbook & local dev instructions

**Prereqs:** docker, kubectl, kind/k3d, helm, java17, go1.21, spark (for running locally), kafka (docker-compose).

**Local dev flow (recommended):**

1. Start local k8s: `k3d cluster create dev-cluster --api-port 6550 -p "8081:80@loadbalancer"`
2. Start Kafka: `docker-compose -f infra/scripts/docker-compose-kafka.yml up -d` (use Redpanda/Confluent images)
3. Build & push local images to k3d registry or load into cluster: `docker build -t fiat2crypto-api-gateway:local ./services/api-gateway && k3d image import ...`
4. Apply k8s manifests: `kubectl apply -f infra/terraform/k8s/ -n fiat2crypto`
5. Run Fraud Scorer in local spark or submit to spark-on-k8s via `spark-submit`.

**Health checks / endpoints:**

* `/health` for all Spring Boot services
* `/metrics` Prometheus metrics
* `/actuator` (secured) for admin

---

## 11. Agile implementation schedule (sprint plan)

The plan below assumes two-week sprints. Team composition: 1 backend (Spring), 1 backend (Go), 1 infra/DevOps, 1 frontend (Flutter + Vue), 1 data/ML engineer (part-time), 1 QA (part-time). Adjust per your team.

### Sprint 0 — Project setup (1 week, optional prep)

* Create repo, branches, ISSUE/TICKET templates, GitHub Projects (kanban)
* Create dev k8s cluster (k3d/kind) + local Kafka docker-compose
* Basic CI pipeline skeleton (build images)

### Sprint 1 — Core Auth, Gateway, Orchestrator (2 weeks)

**Goals:** implement Auth Service (OAuth2) and API Gateway; scaffold Payment Orchestrator.
**Backlog:**

* Auth Service basic (signup, login, OAuth2). (Spring)
* API Gateway routes & auth integration. (Spring)
* Orchestrator skeleton (Go) with REST endpoint and validation. (Go)
* Kafka local setup (dev). (DevOps)
* Dockerfiles + Docker builds for services.

**Deliverable:** Auth + Gateway + Orchestrator running in dev k8s and able to call orchestrator endpoint.

### Sprint 2 — Ledger & Event Bus (2 weeks)

**Goals:** implement Ledger Service and event publishing to Kafka.
**Backlog:**

* Ledger Service CRUD + event producer (outbox pattern). (Spring)
* Configure Kafka topics & Schema Registry (dev). (DevOps)
* Payment Orchestrator produces `transactions.raw` to Kafka. (Go)
* Integration tests for the flow: POST /payments -> transactions.raw appears.

**Deliverable:** End-to-end: API -> Orchestrator -> Kafka -> Ledger consumer writes event.

### Sprint 3 — Fraud Scorer (2 weeks)

**Goals:** Spark Structured Streaming job to consume `transactions.raw` and produce `transactions.scored`.
**Backlog:**

* Implement simple feature enrichers (IP velocity, amount thresholds). (Data)
* Containerize Spark job and test locally. (DevOps)
* Hook Ledger or Notification service to consume `transactions.scored`.

**Deliverable:** Scorer runs in dev cluster and sends scored events; notifications generated.

### Sprint 4 — Notifications & Dashboard (2 weeks)

**Goals:** Notification service + minimal Admin dashboard.
**Backlog:**

* Notification service: webhook + push stub. (Spring)
* Admin dashboard basic UI to list transactions and scores. (Vue)
* Flutter demo app: initiate payment + view status. (Mobile)

**Deliverable:** End-user flow from mobile to notification + admin dashboard view.

### Sprint 5 — Reconciliation & Ops (2 weeks)

**Goals:** nightly reconciliation job + basic monitoring/observability.
**Backlog:**

* Reconciliation CronJob (K8s) that compares ledger counts vs kafka counts. (Spring job)
* Prometheus metrics + Grafana dashboard. (DevOps)
* CI: build + push images + ArgoCD deployment (staging).

**Deliverable:** Reconciliation executed in cluster; monitoring dashboards.

### Sprint 6 — Hardening & polish (2 weeks)

**Goals:** security, secrets, scalability tests, docs.
**Backlog:**

* Integrate Vault or Kubernetes External Secrets for secrets. (DevOps)
* Add mTLS (service mesh) or network policies. (DevOps)
* Add basic load testing (k6) for Orchestrator and Gateway. (QA)
* Write deployment & runbooks.

**Deliverable:** Production-ready MVP with docs and runbooks.

**Total time estimate (MVP):** ~10–12 weeks (including Sprint 0). Adjust based on team size.

**Sprint artifacts (LLM friendly):**
Each sprint should produce:

* Updated `CHANGELOG.md`
* One or more runnable k8s manifests / helm values
* Postman or OpenAPI spec for public endpoints
* Unit + integration tests
* Demo recording (short gif/video) for portfolio

---

## 12. Helpful commands & templates

**Build & run locally (example)**

```bash
# build gate
cd services/api-gateway
./mvnw package -DskipTests
docker build -t fiat2crypto-api-gateway:local .

# build orchestrator
cd services/payment-orchestrator
docker build -t fiat2crypto-payment-orch:local .

# apply k8s manifests
kubectl apply -f infra/terraform/k8s/api-gateway-deployment.yaml
kubectl apply -f infra/terraform/k8s/payment-orch-deployment.yaml
```

**Kafka topics (dev)**

```bash
# Using kafka scripts
kafka-topics.sh --create --bootstrap-server localhost:9092 --topic transactions.raw --partitions 3 --replication-factor 1
kafka-topics.sh --create --bootstrap-server localhost:9092 --topic transactions.scored --partitions 3 --replication-factor 1
```

---

## Appendix: Sample OpenAPI snippet (POST /payments)

```yaml
paths:
  /payments:
    post:
      summary: Initiate a payment
      security:
        - oauth2: [payments.write]
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/PaymentRequest'
      responses:
        '202':
          description: Payment accepted
components:
  schemas:
    PaymentRequest:
      type: object
      properties:
        amount:
          type: number
        currency:
          type: string
        source:
          type: object
        destination:
          type: object
```

---
