terraform {
   required_providers {
    google = {
        source = "hashicorp/google"
      version = "~> 4.0.0"
    }
  }
}

provider "google" {
    project = "alert-flames-276807"
    region = "us-central1"
    credentials = "./key.json"
}