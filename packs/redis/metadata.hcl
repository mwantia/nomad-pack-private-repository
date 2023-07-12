app {
  url    = "https://github.com/redis/redis"
  author = "Redis"
}

pack {
  name        = "redis"
  description = "Custom redis pack, mainly used to deploy a redis cache served to other services like coredns"
  url         = "https://github.com/mwantia/nomad-pack-private-repository/redis"
  version     = "1.0.0.0"
}