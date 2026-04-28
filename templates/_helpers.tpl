{{/*
─────────────────────────────────────────────────────────────
MediTrack — Global Helm helper functions
Environment: both
Phase: 2 — Kubernetes + Helm Implementation
─────────────────────────────────────────────────────────────
*/}}

{{/*
Common labels applied to every resource
*/}}
{{- define "meditrack.labels" -}}
app.kubernetes.io/part-of: meditrack
app.kubernetes.io/managed-by: helm
environment: {{ .Values.global.environment }}
{{- end -}}

{{/*
Full image path using per-service imageTag with fallback to global.imageTag
Usage:
  {{ include "meditrack.image" (dict "root" . "service" .Values.global.userService) }}
*/}}
{{- define "meditrack.image" -}}
{{- $root := .root -}}
{{- $service := .service -}}
{{- printf "%s/%s:%s" $root.Values.global.registry $service.image (default $root.Values.global.imageTag $service.imageTag) -}}
{{- end -}}

{{/*
Init container: wait for a service on a specific port
*/}}
{{- define "meditrack.initWait" -}}
- name: wait-for-{{ .name }}
  image: busybox:1.36
  command:
    - sh
    - -c
    - |
      echo "Waiting for {{ .name }}:{{ .port }}..."
      until nc -z {{ .name }} {{ .port }}; do
        echo "{{ .name }}:{{ .port }} not ready, retrying in 3s..."
        sleep 3
      done
      echo "{{ .name }}:{{ .port }} is ready!"
  resources:
    requests:
      cpu: 50m
      memory: 64Mi
    limits:
      cpu: 50m
      memory: 128Mi
  securityContext:
    allowPrivilegeEscalation: false
    capabilities:
      drop: ["ALL"]
{{- end -}}

{{/*
Standard deployment strategy
*/}}
{{- define "meditrack.deploymentStrategy" -}}
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
{{- end -}}

{{/*
Container-level security context (all containers)
*/}}
{{- define "meditrack.containerSecurityContext" -}}
securityContext:
  allowPrivilegeEscalation: false
  capabilities:
    drop: ["ALL"]
{{- end -}}

{{/*
Standard lifecycle hook
*/}}
{{- define "meditrack.lifecycle" -}}
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "sleep 5"]
{{- end -}}

{{/*
Standard probes for application services
*/}}
{{- define "meditrack.appProbes" -}}
startupProbe:
  httpGet:
    path: /health
    port: {{ .port }}
  initialDelaySeconds: 10
  periodSeconds: 5
  failureThreshold: 12
livenessProbe:
  httpGet:
    path: /health
    port: {{ .port }}
  periodSeconds: 15
  timeoutSeconds: 5
  failureThreshold: 3
readinessProbe:
  httpGet:
    path: /health
    port: {{ .port }}
  periodSeconds: 10
  timeoutSeconds: 3
  failureThreshold: 3
{{- end -}}
