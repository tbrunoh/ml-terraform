terraform {
  cloud {
    organization = "silicon-mara"

    workspaces {
      name = "sm-resources"
    }
  }
}
