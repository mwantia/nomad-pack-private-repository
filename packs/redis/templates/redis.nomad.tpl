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

  group "cache" {
    count = [[ .my.app_count ]]

    network {
      mode = [[ .my.network_mode | quote ]]
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
      port = [[ .my.consul_service_port ]]
      tags = [[ .my.consul_tags | toStringList ]]

      [[- if .my.consul_connect_enable ]]
      connect {
        sidecar_service {}
      }
      [[- end ]]
    }
    [[- end ]]

    [[- if .my.ephemeral_disk ]]
    ephemeral_disk {
      migrate = [[ .my.ephemeral_disk.migrate ]]
      size    = [[ .my.ephemeral_disk.size ]]
      sticky  = [[ .my.ephemeral_disk.sticky ]]
    }
    [[- end]]

    restart {
      attempts = [[ .my.restart_attempts ]]
      interval = "30m"
      delay    = "15s"
      mode     = "fail"
    }

    task "redis" {
      driver = "docker"

      config {
        image = "[[ .my.task_docker_image.name ]]:[[ .my.task_docker_image.version ]]"

        mount {
          type = "tmpfs"
          target = "/data"
          readonly = false
          tmpfs_options {
            size = 1024000000
          }
        }
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

      resources {
        cpu    = [[ .my.task_resources.cpu ]]
        memory = [[ .my.task_resources.memory ]]
      }
    }
  }
}