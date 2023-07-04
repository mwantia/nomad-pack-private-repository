job "nomad-pack-[[ template "name" . ]]" {
  
  [[ template "region" . ]]
  datacenters = [[ .traefik.datacenters | toStringList ]]

  constraint {
    attribute = "${attr.kernel.name}"
    value     = "linux"
  }

  constraint {
    attribute = "${meta.location}"
    value     = "[[ .traefik.location.name ]]"
  }

  group "group" {
    network {
      mode = "bridge"

      port "admin" {
        to = 8080
      }

      port "web" {
        to     = [[ .traefik.web_port ]]
        static = [[ .traefik.web_port ]]
      }

      port "websecure" {
        to     = [[ .traefik.websecure_port ]]
        static = [[ .traefik.websecure_port ]]
      }
    }

    service {
      name = "[[ template "name" . ]]"
      port = [[ .traefik.web_port ]]
      tags = [ "traefik.enable=true", "traefik.http.routers.[[ template "name" . ]].service=api@internal" ]
    
      connect {
        native = true
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:[[ .traefik.version ]]"

        mount {
          type = "bind"
          target = "/etc/traefik/traefik.yml"
          source = "local/traefik.yaml"
          readonly = true
          bind_options { propagation = "rshared" }
        }
      }

      template {
        data = <<-EOF
        entrypoints:
          web:
            address: ':[[ .traefik.web_port ]]'
          websecure:
            address: ':[[ .traefik.websecure_port ]]'

        api:
          dashboard: true
          insecure: true
        
        metrics:
          prometheus:
            addRoutersLabels: true
            addServicesLabels: true
        
        ping: { }
        
        providers:
          consulcatalog:
            servicename: [[ template "name" . ]]
            endpoint:
              address: '{{% env "attr.unique.network.ip-address" %}}:8500'
            connectAware: true
            connectByDefault: true
            exposedByDefault: false
            defaultRule: "Host(`{{ .Name }}.[[ .traefik.location.domain ]]`)"
            constraints: 'TagRegex(`traefik\.location=.*([[ .traefik.location.name ]])`)'
        EOF
        destination     = "local/traefik.yaml"
        change_mode     = "restart"
        left_delimiter  = "{{%"
        right_delimiter = "%}}"
      }

      resources {
        cpu    = [[ .traefik.resources.cpu ]]
        memory = [[ .traefik.resources.memory ]]
      }
    }
  }
}