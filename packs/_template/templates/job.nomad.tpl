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

  group "<serviceName>" { # <-- Placeholder, please update!!
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

    task "<serviceName>" { # <-- Placeholder, please update!!
      driver = "docker"

      config {
        image = "[[ .my.task_docker_image.name ]]:[[ .my.task_docker_image.version ]]"
      }

      # <-- Placeholder, please update!!
      # <-- Placeholder, please update!!
      # <-- Placeholder, please update!!

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