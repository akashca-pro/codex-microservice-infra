#!/usr/bin/env bash
set -euo pipefail

CHART_DIR=helm
SERVICES=(auth-user problem code-execution code-manage gateway collab)

mkdir -p $CHART_DIR
for svc in "${SERVICES[@]}"; do
  chart_path="$CHART_DIR/$svc"
  mkdir -p "$chart_path/templates"
  cat > "$chart_path/Chart.yaml" <<EOF
apiVersion: v2
name: $svc
description: Codex $svc microservice
type: application
version: 0.1.0
appVersion: "0.0.1"
EOF

  cat > "$chart_path/values.yaml" <<EOF
replicaCount: 1

image:
  repository: akashcapro/codex-$svc
  tag: "0.0.4"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  grpcPort: 50051
  httpPort: 4000
  metricsPort: 9100

resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi

env: {}
EOF

  cat > "$chart_path/templates/_helpers.tpl" <<'EOF'
{{- define "svc.name" -}}
{{ include "common.fullname" . }}-{{ .Chart.Name }}
{{- end -}}

{{- define "svc.fullname" -}}
{{ printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}
EOF

  cat > "$chart_path/templates/namespace.yaml" <<'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: app-services
EOF

  cat > "$chart_path/templates/service.yaml" <<'EOF'
apiVersion: v1
kind: Service
metadata:
  name: {{ include "svc.fullname" . }}
  namespace: app-services
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "svc.fullname" . }}
  ports:
    - name: grpc
      port: {{ .Values.service.grpcPort | default 50051 }}
      targetPort: {{ .Values.service.grpcPort | default 50051 }}
    - name: http
      port: {{ .Values.service.httpPort | default 4000 }}
      targetPort: {{ .Values.service.httpPort | default 4000 }}
    - name: metrics
      port: {{ .Values.service.metricsPort | default 9100 }}
      targetPort: {{ .Values.service.metricsPort | default 9100 }}
EOF

  cat > "$chart_path/templates/deployment.yaml" <<'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "svc.fullname" . }}
  namespace: app-services
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "svc.fullname" . }}
  template:
    metadata:
      labels:
        app: {{ include "svc.fullname" . }}
    spec:
      initContainers:
        - name: wait-for-redis
          image: busybox:1.36.1
          command: ["sh","-c","until nc -z -w 1 redis 6379; do sleep 2; done;"]
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.grpcPort | default 50051 }}
            - containerPort: {{ .Values.service.metricsPort | default 9100 }}
          env:
            - name: REDIS_URL
              value: "redis://redis:6379"
            {{- range \$k, \$v := .Values.env }}
            - name: {{ \$k }}
              value: "{{ \$v }}"
            {{- end }}
          resources:
            requests:
              cpu: {{ .Values.resources.requests.cpu }}
              memory: {{ .Values.resources.requests.memory }}
            limits:
              cpu: {{ .Values.resources.limits.cpu }}
              memory: {{ .Values.resources.limits.memory }}
EOF

  # simple secrets template (for local testing)
  cat > "$chart_path/templates/secrets.yaml" <<'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: app-services
type: Opaque
stringData:
  # replace placeholders with real values or set via --set-file/--set
  JWT_SECRET: "dev-jwt-secret"
  SMTP_USER: "you@example.com"
  SMTP_PASS: "secret"
EOF

done

# Umbrella chart
mkdir -p "$CHART_DIR/umbrella-chart/templates"
cat > "$CHART_DIR/umbrella-chart/Chart.yaml" <<EOF
apiVersion: v2
name: codex-umbrella
description: Umbrella chart to deploy all services
type: application
version: 0.1.0
appVersion: "0.0.1"
EOF

cat > "$CHART_DIR/umbrella-chart/values.yaml" <<EOF
# can include subchart overrides later
EOF

echo "Scaffolded charts under $CHART_DIR for: ${SERVICES[*]}"
