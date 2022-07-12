provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_storage_bucket" "function_bucket" {
    name     = "${var.project_id}-function"
    location = var.region
}

resource "google_storage_bucket" "action_bucket" {
    name     = "${var.project_id}-action"
    location = var.region
}


data "archive_file" "source_file" {
    type        = "zip"
    source_dir  = "../src"
    output_path = "/code/function.zip"
}

resource "google_storage_bucket_object" "zip_file" {
    name   = "index.zip"
    bucket = google_storage_bucket.function_bucket.name
    source       = data.archive_file.source_file.output_path
    content_type = "application/zip"

}

resource "google_cloudfunctions_function" "function" {
    name                  = "function-trigger-on-cloud-storage"
    runtime               = "python39"

    source_archive_bucket = google_storage_bucket.function_bucket.name
    source_archive_object = google_storage_bucket_object.zip_file.name
    entry_point           = "function_for_object_create_or_update"
    
    event_trigger {
        event_type = "google.storage.object.finalize"
        resource   = "${var.project_id}-action"
    }

    depends_on            = [
        google_storage_bucket.function_bucket,
        google_storage_bucket_object.zip_file
    ]
}

resource "google_cloudfunctions_function_iam_member" "function-invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  member = "allUsers"
}
