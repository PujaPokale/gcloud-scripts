variable "project_id" {
  type        = string
  description = "The project ID to manage the Pub/Sub resources"
  default = "my-gcp-pubsub-project-id"
}

variable "topic" {
  type        = string
  description = "The Pub/Sub topic name"
  default = "my-topic"
}

variable "create_topic" {
  type        = bool
  description = "Specify true if you want to create a topic"
  default     = true
}

variable "create_subscriptions" {
  type        = bool
  description = "Specify true if you want to create subscriptions"
  default     = true
}
