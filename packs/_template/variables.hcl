# -------------------------------------
#       Job Constraint Variables
# -------------------------------------

variable "node_constraint" {
  description     = "Limits the deployment to nodes that match the specified constraint (regexp)."
  type            = object({
    cpu_arch      = string
    node_location = string
  })
}

# -------------------------------------
#         Global Job Variables
# -------------------------------------

variable "job_name" {
  description = "Name of the Nomad job -- Overrides the default pack name"
  type        = string
  default     = "" # If "", the pack name will be used
}

variable "job_type" {
  description = "Type of the Nomad job"
  type        = string
  default     = "service" 
}

variable "datacenters" {
  description = "Datacenters this job will be deployed"
  type        = list(string)
  default     = [ "*" ]
}

variable "region" {
  description = "Region where the job should be placed."
  type        = string
  default     = "global"
}

variable "app_count" {
  description = "Number of instances to deploy"
  type        = number
  default     = 1
}

variable "update" {
  description         = "Job update parameters"
  type                = object({
    min_healthy_time  = string
    healthy_deadline  = string
    progress_deadline = string
    auto_revert       = bool
  })
  default             = {
    min_healthy_time  = "10s",
    healthy_deadline  = "5m",
    progress_deadline = "10m",
    auto_revert       = true,
  }
}

variable "restart_attempts" {
  description = "Number of attempts to restart the job due to updates, failures, etc"
  type        = number
  default     = 2
}

variable "network_mode" {
  description = "Job network mode specifications"
  type        = string
  default     = "bridge"
}

variable "ephemeral_disk" {
  description = "Ephemeral disk space to assign this job"
  type        = object({
    migrate   = bool
    size      = number
    sticky    = bool
  })
}

# -------------------------------------
#         Job Task Variables
# -------------------------------------

variable "task_docker_image" {
  description = "Redis Docker image."
  type        = object({
    name      = string
    version   = string
  })
  default     = {
    name      = "mwantia/coredns-custom" 
    version   = "latest" 
  }
}

variable "task_env_variables" {
  description = "List of environment variables that are provided to the task."
  type        = list(object({
    key       = string
    value     = string
  }))
}

variable "task_resources" {
  description = "Resources to assign this job"
  type        = object({
    cpu       = number
    memory    = number
  })
  default     = {
    cpu       = 250, # 250 MHz
    memory    = 128  # 128 MB
  }
}

variable "task_artifacts" {
  description   = "Define external artifacts for CoreDNS."
  type          = list(object({
    source      = string
    destination = string
    mode        = string
    options     = map(string)
  }))
}

variable "task_templates" {
  description   = "Define additional templates for CoreDNS."
  type          = list(object({
    data        = string
    destination = string
    change_mode = string
  }))
}

# -------------------------------------
#    Consul Registration Variables
# -------------------------------------

variable "register_consul_service" {
  description = "Defined, if this job should be registered in Consul (consul_service_name)."
  type        = bool
  default     = true
}

variable "consul_service_name" {
  description = "Name used if the job will be registered in Consul"
  type        = string
  default     = "<serviceName>" # <-- Placeholder, please update!!
}

variable "consul_service_port" {
  description = "Port used if the job will be registered in Consul"
  type        = number
  default     = "<servicePort>" # <-- Placeholder, please update!!
}

variable "consul_tags" {
  description = "Tags to use for job"
  type        = list(string)
  default     = [ "<serviceTags>" ] # <-- Placeholder, please update!!
}

variable "consul_connect_enable" {
  description = "Defined, if Consul Connect should be enabled for this job."
  type        = bool
  default     = true
}