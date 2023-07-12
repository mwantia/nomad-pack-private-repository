job [[ template "job_name" . ]] {
  [[ template "region" . ]]

  datacenters = [[ .my.datacenters | toStringList ]]
  type        = [[ .my.job_type | quote ]]

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  [[- if .my.node_constraint ]]
  constraint {
    attribute = "${attr.cpu.arch}"
    operator  = "regexp"
    value     = [[ .my.node_constraint.cpu_arch | quote ]]
  }

  constraint {
    attribute = "${meta.node.location}"
    operator  = "regexp"
    value     = [[ .my.node_constraint.node_location | quote ]]
  }
  [[- end ]]  

  group "coredns" {
    count = [[ .my.app_count ]]

    network {
      mode = [[ .my.network_mode | quote ]]

      [[- if .my.coredns_dns ]]
      port "dns" {
        to     = [[ .my.coredns_dns.port ]]
        [[- if not .my.coredns_dns.dynamic ]]
        static = [[ .my.coredns_dns.port ]]
        [[- end ]]
      }
      [[- end ]]

      [[- if .my.coredns_health_check ]] [[- if .my.coredns_health_check.enabled ]]
      port "health" {
        to     = [[ .my.coredns_health_check.port ]]
        [[- if not .my.coredns_health_check.dynamic ]]
        static = [[ .my.coredns_health_check.port ]]
        [[- end ]]
      }
      [[- end ]] [[- end ]]

      [[- if .my.coredns_prometheus_metrics ]] [[- if .my.coredns_prometheus_metrics.enabled ]]
      port "metrics" {
        to     = [[ .my.coredns_prometheus_metrics.port ]]
        [[- if not .my.coredns_prometheus_metrics.dynamic ]]
        static = [[ .my.coredns_prometheus_metrics.port ]]
        [[- end ]]
      }
      [[- end ]] [[- end ]]
    }

    update {
      min_healthy_time  = [[ .my.update.min_healthy_time | quote ]]
      healthy_deadline  = [[ .my.update.healthy_deadline | quote ]]
      progress_deadline = [[ .my.update.progress_deadline | quote ]]
      auto_revert       = [[ .my.update.auto_revert ]]
    }

    [[- if .my.register_consul_service ]]
    service {
      name = [[ .my.consul_service_name | quote ]]
      [[- if .my.coredns_dns ]]
      port = [[ .my.coredns_dns.port ]]
      [[- end ]]
      tags = [[ .my.consul_tags | toStringList ]]

      meta {
        [[- if .my.coredns_prometheus_metrics ]] [[- if .my.coredns_prometheus_metrics.enabled ]]
        metrics_port = "${NOMAD_HOST_PORT_metrics}"
        [[- end ]] [[- end ]]
        [[- if .my.coredns_health_check ]] [[- if .my.coredns_health_check.enabled ]]
        healthy_port = "${NOMAD_HOST_PORT_health}"
        [[- end ]] [[- end ]]
      }

      [[- if .my.consul_connect_enable ]]
      connect {
        sidecar_service {
          [[- if .my.coredns_redis_cache_connect ]] [[- if .my.coredns_redis_cache_connect.enabled ]]
          proxy {
            upstreams {
              destination_name = [[ .my.coredns_redis_cache_connect.service_name | quote ]]
              local_bind_port  = [[ .my.coredns_redis_cache_connect.local_port ]]
            }
          }
          [[- end ]] [[- end ]]
        }
      }
      [[- end ]]

      [[- if .my.coredns_health_check ]] [[- if .my.coredns_health_check.enabled ]]
      check {
        [[- if .my.consul_connect_enable ]]
        expose   = true
        [[- end ]]
        port     = "health"
        type     = "http"
        name     = "health"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
      [[- end ]] [[- end ]]
    }
    [[- end ]]

    restart {
      attempts = [[ .my.restart_attempts ]]
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "coredns" {
      driver = "docker"

      config {
        image = "[[ .my.task_docker_image.name ]]:[[ .my.task_docker_image.version ]]"

        mount {
          type = "bind"
          target = "/coredns/Corefile"
          source = "local/Corefile"
          readonly = true
          bind_options { propagation = "rshared" }
        }
      }
      template {
        destination = "local/Corefile"
        change_mode = "restart"
        data        = <<-EOF
        [[- if .my.coredns_corefile_override ]]
        [[ .my.coredns_corefile_override ]]
        [[- else ]]
        (default) {
          metadata
          log
          errors
        }

        (rcache) {
          cache 60
          [[- if .my.coredns_redis_cache_connect ]] [[- if .my.coredns_redis_cache_connect.enabled ]]
          redisc [[ .my.coredns_redis_cache_connect.cache_ttl ]] {
            endpoint 127.0.0.1:[[ .my.coredns_redis_cache_connect.local_port ]]
          }
          [[- end ]] [[- end ]]
        }

        (metrics) {
          [[- if .my.coredns_prometheus_metrics ]] [[- if .my.coredns_prometheus_metrics.enabled ]]
          prometheus :[[ .my.coredns_prometheus_metrics.port ]]
          [[- end ]] [[- end ]]
        }

        (healthc) {
          [[- if .my.coredns_health_check ]] [[- if .my.coredns_health_check.enabled ]]
          health :[[ .my.coredns_health_check.port ]]
          [[- end ]] [[- end ]]
        }

        [[- if .my.coredns_corefile_zones ]] [[- range $zone := .my.coredns_corefile_zones ]]
        [[ $zone.name ]] {
          import default
          [[- if $zone.enable_cache ]]
          import rcache
          [[- end ]] [[- if eq $zone.name "." ]]
          import healthc
          [[- end ]] [[- if $zone.enable_metrics ]]
          import metrics
          [[- end ]]

          [[ $zone.data ]]
        }
        [[- end ]] [[- end ]]
        [[- end ]]
        EOF
      }

      [[- if .my.task_env_variables ]]
      template {
        data        = <<-EOH
        [[- range $var := .my.task_env_variables ]]
        [[ $var.key ]] = "[[ $var.value ]]"
        [[- end ]]
        EOH
        change_mode = "noop"
        destination = "secrets/file.env"
        env         = true
      }
      [[- end ]]

      [[- if .my.task_artifacts ]] [[- range $artifact := .my.task_artifacts ]]
      artifact {
        source      = [[ $artifact.source | quote ]]
        destination = [[ $artifact.destination | quote ]]
        mode        = [[ $artifact.mode | quote ]]
        [[- if $artifact.options ]]
        options {
          [[- range $option, $val := $artifact.options ]]
          [[ $option ]] = [[ $val | quote ]]
          [[- end ]]
        }
        [[- end ]]
      }
      [[- end ]] [[- end ]]

      [[- if .my.task_templates ]] [[- range $template := .my.task_templates ]]
      template {
        data        = [[ $template.data | quote ]]
        destination = [[ $template.destination | quote ]]
        change_mode = [[ $template.change_mode | quote ]]
      }
      [[- end ]] [[- end ]]

      [[- if .my.task_resources ]]
      resources {
        cpu    = [[ .my.task_resources.cpu ]]
        memory = [[ .my.task_resources.memory ]]
      }
      [[- end ]]
    }
  }
}