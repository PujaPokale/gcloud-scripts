data "google_project" "project" {
  project_id = var.project_id
}

locals {
  pubsub_service_account_email     = "my-sa-${data.google_project.project_id}@my-gcp-pubsub-project.iam.gserviceaccount.com"
}

resource "google_pubsub_topic" "topic" {
  count        = var.create_topic ? 1 : 0
  project      = var.project_id
  name         = var.topic
}

resource "google_pubsub_subscription" "my-subscription" {
 count = var.create_subscriptions ? 1 : 0
 name    = "my-subscription"
  topic   = google_pubsub_topic.topic.name
  project = var.project_id

  message_retention_duration = "1200s"
  retain_acked_messages      = true
  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "864000.0s"
  }
  retry_policy {
    minimum_backoff = "3.5s"
    maximum_backoff = "10s"
  }
  depends_on = [
    google_pubsub_topic.topic,
  ]
}


resource "google_pubsub_topic_iam_member" "pull_topic_binding" {
  project = var.project_id
  topic   = google_pubsub_topic.topic.id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${local.pubsub_service_account_email}"
  depends_on = [
    google_pubsub_topic.topic,
  ]
}

resource "google_pubsub_subscription_iam_member" "pull_subscription_binding" {
  project      = var.project_id
  subscription = google_pubsub_subscription.my-subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${local.pubsub_service_account_email}"
  depends_on = [
    google_pubsub_subscription.my-subscription,
  ]
}

resource "google_service_account" "service_account" {
  account_id   = "service-account-id"
  display_name = "gcp-sa-for-pub-sub"
}
