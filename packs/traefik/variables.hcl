variable "name" {
  description = "Name of the Nomad service."
  type        = string
  default     = "traefik"
}

variable "version" {
  description = ""
  type        = string
  default     = "latest"
}

variable "datacenters" {
  description = "List of datacenters this job will be deployed to."
  type        = list(string)
  default     = [ "*" ]
}

variable "region" {
  description = "Region where the job should be placed."
  type        = string
  default     = "global"
}

variable "location" {
  description = ""
  type        = object({
    name      = string
    domain    = string
  })
  default     = {
    name      = "onprem"
    domain    = "proxy.lan.wantia"
  }
}

variable "web_port" {
  description = ""
  type        = number
  default     = 80
}

variable "websecure_port" {
  description = ""
  type        = number
  default     = 443
}

variable "resources" {
  description = "Resources to assign this job"
  type        = object({
    cpu       = number
    memory    = number
  })
  default     = {
    cpu       = 100,
    memory    = 256
  }
}