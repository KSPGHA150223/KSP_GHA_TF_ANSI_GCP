# GCS backend configuration has the following key-value pairs.

# Bucket: Google storage bucket name. previously created GCS bucket name
# Prefix: Folders inside the bucket.  TF will create this folder path inside provided bucket name above
# Credentials: Path to google service account file. It's mandatory because it has to access existing GCS on GCP 

# the reason credentials are needed in both the backend configuration and the provider block is because they serve different purposes 
# and are used in different parts of the Terraform process:

# Backend Configuration Credentials: Used to authenticate Terraform when interacting with the backend storage where your state files are stored.
# Provider Block Credentials: Used to authenticate Terraform with the cloud provider's APIs to manage resources within your cloud environment.
# Each set of credentials ensures that Terraform can perform its specific tasks securely and with the necessary permissions. 
terraform {
  backend "gcs" {
    bucket = "ksp-states-demo"  # create gs://tf-states-demo
    prefix = "tf-state" # create folders "terraform/state" --> gs://tf-states-demo/terraform/state/
    ######## On run "Terraform init", TF will put default state at gs://tf-states-demo/terraform/state/default.tfstate 
    #credentials = "ksp-gcp-58608-940c0b458e09.json"   # this is needed if you run from local TF CLI
  }
}

variable "credentials_file" {
  type        = string
  description = "credentials"
  default     = "ksp-gcp-58608-940c0b458e09.json"
}
variable "region" {
  type        = string
  description = "region11"
  default     = "us-west4"
}
locals {
  project       = "ksp-gcp-58608"
  instance_name = "myks-tf-ansi-vm1"
  instance_zone = "us-west4-a"
  machine_type  = "e2-medium"
  image         = "ubuntu-os-cloud/ubuntu-2004-lts"
  instance_labels = {
    env = "dev"
    app = "web"
  }
}


provider "google" {
  project     = local.project
  #credentials = file(var.credentials_file)
  region      = var.region
  zone        = local.instance_zone
}

resource "google_compute_firewall" "allow-ssh" {
  name    = "allow-ssh"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["22","80"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_instance" "my-tf-ansi-ks" {
  name         = local.instance_name
  machine_type = local.machine_type
  boot_disk {
    initialize_params {
      image = local.image
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  
}

# Output the public IP address of the created instance
output "public_ip" {
  value = google_compute_instance.my-tf-ansi-ks.network_interface.0.access_config.0.nat_ip
}