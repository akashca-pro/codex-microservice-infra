# Codex Infrastructure

This repository defines the production and development infrastructure for the **Codex** microservice platform. It includes Kubernetes manifests, Helm charts, observability configuration and CI/CD workflows used to deploy and manage all backend services.

---

## 1. Repository Overview

Codex consists of the following microservices:

* **gateway-service**
* **auth-user-service**
* **problem-service**
* **code-manage-service**
* **code-execution-service**
* **collab-service**

This repo provides:

* Helm umbrella chart and per-service Helm charts
* Kubernetes manifests (ingress, namespaces, secrets, infra components)
* Docker Compose environment for local development
* Complete observability stack: OTel, Prometheus, Loki, Tempo, Grafana
* CI/CD pipelines for both service-level and infra-level delivery

---

## 2. Architecture Overview

Codex runs on Kubernetes (GKE Standard), with each microservice deployed as a separate workload. Key architectural components:

| Component               | Description                                                          |
| ----------------------- | -------------------------------------------------------------------- |
| **Helm Umbrella Chart** | Standardises deployment, scaling and configuration for all services. |
| **Helm Subcharts**      | Independent charts for each microservice.                            |
| **Ingress NGINX**       | Routes incoming traffic to gateway and collab websocket.             |
| **Kafka**               | Handles async communication between code-manage and code-execution.  |
| **Redis**               | Caching and Socket.io adapter for collab service.                    |
| **Databases**           | PostgreSQL (auth-user), MongoDB (problem, collab).                   |
| **Observability Stack** | Prometheus, Loki, Tempo, Grafana with OpenTelemetry instrumentation. |

---

## 3. Repository Structure

```
codex-microservice-infra/
│
├── docker-compose.yml               # Local full stack (Kafka, Redis, DBs, services)
│
├── helm/
│   ├── auth-user/                   # Service-specific Helm charts
│   ├── code-execution/
│   ├── code-manage/
│   ├── collab/
│   ├── gateway/
│   ├── problem/
│   │
│   ├── common/                      # Shared infra: ingress, kafka, redis, secrets
│   ├── common-lib/                  # Shared deployment/service templates
│   │
│   ├── codex/                       # Umbrella Helm chart
│   │   ├── Chart.yaml
│   │   ├── charts/                  # Packaged subcharts
│   │   └── values.yaml              # Global values for entire platform
│   │
│   ├── ingress-controller-values/   # NGINX ingress Helm values
│   ├── observability-values/        # OTel, Prometheus, Grafana, Loki, Tempo, Promtail
│   └── helmfile.yaml
│
├── k8s/                             # Raw Kubernetes manifests
│   ├── 00-namespaces.yaml
│   ├── 01-secrets.yaml
│   ├── <service>-service.yaml
│   ├── ingress.yaml
│   ├── kafka/
│   │   ├── kafka.yaml
│   │   └── kafka-ui.yaml
│   ├── redis.yaml
│   ├── grafana-proxy.yaml
│   └── problem-service.yaml
│
├── prometheus.yml                   # scrape configurations for Docker compose
│
└── scripts/                         # Utility scripts
    ├── deploy.sh
    ├── deploy-all.sh
    ├── helm-deploy.sh
    ├── scaleup-all.sh
    └── scaledown-all.sh
```

---

## 4. Communication Model

### **gRPC (synchronous)**

* Gateway ↔ Auth User
* Gateway ↔ Problem
* Gateway ↔ Code Manage
* Gateway ↔ Collab (session creation)
* Problem ↔ Auth User
* Code Manage ↔ Problem

### **Kafka (asynchronous)**

* Code Manage → Code Execution (run, submit, custom code execution)
* Code Execution → Code Manage (results)

### **WebSockets (real-time)**

* Collab service using Socket.io
* YJS shared document awareness
* Redis adapter for multi-pod scaling
* MongoDB for persistent snapshot for recovery

---

## 5. CI/CD Pipeline

Codex uses separate pipelines for each microservice repo and a GitOps workflow for infrastructure.

### **Service-Level CI/CD** (each microservice repo)

* Push to dev/feature branch → Lint, test, build (no push)
* Merge to main → Build production Docker image → Push to Docker Hub
* **ArgoCD Image Updater** detects new images → updates workloads in GKE

This ensures services deploy independently without infra changes.

---

## 6. Infrastructure-Level CI/CD

The infra repo defines cluster state. Deployment flow:

1. Update Helm charts or Kubernetes manifests
2. Push to `main`
3. ArgoCD detects changes and synchronizes cluster state
4. GKE applies updated configurations

This provides:

* Full GitOps environment
* Versioned cluster configuration
* Zero manual kubectl operations

---

## 7. Observability

Codex includes complete distributed tracing, logging and metrics:

* **OpenTelemetry Collector** auto-instrumented traces (Express, gRPC, Kafka, DBs)
* **Tempo** for trace storage
* **Prometheus** for metrics and HPA autoscaling signals
* **Loki** for logs
* **Grafana** dashboards for all telemetry sources

---

## 8. Service Links

| Service        | Repository                                                                                                                 |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------|
| Auth User      | [https://github.com/akashca-pro/codex-auth-user-service](https://github.com/akashca-pro/codex-auth-user-service)           |
| API Gateway    | [https://github.com/akashca-pro/codex-gateway-service](https://github.com/akashca-pro/codex-gateway-service)               |
| Problem        | [https://github.com/akashca-pro/codex-problem-service](https://github.com/akashca-pro/codex-problem-service)               |
| Code Manage    | [https://github.com/akashca-pro/codex-code-manage-service](https://github.com/akashca-pro/codex-code-manage-service)       |
| Code Execution | [https://github.com/akashca-pro/codex-code-execution-service](https://github.com/akashca-pro/codex-code-execution-service) |
| Collab         | [https://github.com/akashca-pro/codex-collab-service](https://github.com/akashca-pro/codex-collab-service)                 |

---

## 9. Deployment Strategy Summary

* Microservices build and publish images via GitHub Actions
* Infra repo controls all Kubernetes behaviour
* ArgoCD handles continuous reconciliation and Helm deployment
* Umbrella chart enforces consistent standards across services
* HPA autoscaling based on CPU and memory
* Running on **GKE Standard** with node autoscaling

---

## 10. License

MIT
