{{/*
Define the full service name
*/}}
{{- define "svc.fullname" -}}
{{ .Chart.Name }}
{{- end -}}


{{/*
Common Deployment template
*/}}
{{- define "common-lib.deployment" }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "svc.fullname" . }}
  namespace: app-services
spec:
  {{- if not .Values.autoscaling.enabled }}
  replicas: {{ .Values.replicaCount }}
  {{- end }}
  selector:
    matchLabels:
      app: {{ include "svc.fullname" . }}
  template:
    metadata:
      labels:
        app: {{ include "svc.fullname" . }}
    spec:
      {{- if .Values.initContainers }}
      initContainers:
        {{- toYaml .Values.initContainers | nindent 8 }}
      {{- end }}

      containers:
        - name: {{ include "svc.fullname" . }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}

          ports:
            {{- range $name, $port := .Values.service.ports }}
            - name: {{ $name }}
              containerPort: {{ $port }}
            {{- end }}

          env:
            {{- range .Values.env }}
            - name: {{ .name }}
              value: "{{ .value }}"
            {{- end }}

          {{- if .Values.envFrom }}
          envFrom:
            {{- toYaml .Values.envFrom | nindent 12 }}
          {{- end }}

          resources:
            {{- toYaml .Values.resources | nindent 12 }}

          {{- with .Values.probes }}
          livenessProbe:
            {{- toYaml .liveness | nindent 12 }}
          readinessProbe:
            {{- toYaml .readiness | nindent 12 }}
          {{- end }}
---
{{- end }}


{{/*
Common Service template
*/}}
{{- define "common-lib.service" }}
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
    {{- range $name, $port := .Values.service.ports }}
    - name: {{ $name }}
      port: {{ $port }}
      targetPort: {{ $port }}
    {{- end }}
{{- end }}


{{/*
Common HPA template
*/}}
{{- define "common-lib.hpa" }}
{{- if and .Values.autoscaling .Values.autoscaling.enabled }}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "svc.fullname" . }}
  namespace: app-services
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "svc.fullname" . }}

  minReplicas: {{ .Values.autoscaling.minReplicas }}
  maxReplicas: {{ .Values.autoscaling.maxReplicas }}

  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.cpu }}

    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.autoscaling.memory }}

{{- end }}
{{- end }}
