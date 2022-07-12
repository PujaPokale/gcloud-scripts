provider "google" {
  region = "us-central1"
  project = "cloud-sql-project"
}

resource "google_project_service" "workflow" {
  service            = "workflows.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "workflow_sa" {
  account_id   = "my-workflow-sa"
  display_name = "this is my Workflow Service Account"
}

resource "google_workflows_workflow" "workflow_for_cloud_storage" {
  name            = "my-workflow-for-cloud-storage"
  region          = "us-central1"
  description     = "This is the workflow for cloud storage"
  service_account = google_service_account.workflow_sa.id
  source_contents = <<-EOF
  
main:
  params: []
  steps:  
  - init:
    assign:
      - project_id: $${sys.get_env("GOOGLE_CLOUD_PROJECT_ID")}
      - location: "us-central1"

  - create_bucket:
    call: googleapis.storage.v1.buckets.insert
    args:
      project: $${project_id}
      body:
        name: $${my_bucket_name}

  - get_bucket:   
    call: googleapis.storage.v1.buckets.get
    args:
      bucket: $${my_bucket_name}

  - upload_object_type:
    call: googleapis.storage.v1.objects.insert
    args:
      bucket: $${my_bucket_name}
      contentType: "media-type"  
      name: $${object_name}
      body: "hello world, this is an object inside a bucket"

  - get_object_data:
    call: googleapis.storage.v1.objects.get
    args:
      bucket: $${my_bucket_name}
      object: $${object_name}
      alt: "media-type"
    result: object_data    

  - update_object_for_specific_content_type:
    switch:
      - condition: $${object_data.body.alt == "pdf"}
        next: update_object_to_txt_type
      - condition: $${object_data.body.alt == "json"}
        next: the_end

  - update_object_to_txt_type:
    call: googleapis.storage.v1.objects.update
    args:
      bucket: $${my_bucket_name}
      object: $${object_name}
      contentType: "txt"

  - the_end:
    return: "SUCCESS"
EOF
 
  depends_on = [google_project_service.workflow]
}
