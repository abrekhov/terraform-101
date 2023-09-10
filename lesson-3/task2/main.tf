module "cloud" {
  source = "github.com/terraform-yc-modules/terraform-yc-cloud"

  organization_id    = "fhiebhq3nt2s69cuhrmt"
  billing_account_id = "dih9uo8e4vkgemetvia8"

  cloud = {
    name        = "cloud-one"
    description = "One cloud"
  }


  folders = [
    {
      name        = "prod-folder"
      description = "Production environment"
    },
    {
      name        = "dev-folder"
      description = "Development environment"
    },
    {
      name        = "infra-folder"
      description = "Infrastructure folder"
    }
  ]


  groups = [
    {
      name        = "k8s-admins"
      description = "Kubernetes infrastructure administrators"
      cloud_roles = ["k8s.admin"]
      folder_roles = [
        {
          folder_name = "prod-folder"
          roles       = ["k8s.tunnelClusters.agent", "container-registry.images.puller"]
        },
        {
          folder_name = "infra-folder"
          roles       = ["k8s.clusters.agent", "container-registry.images.puller", "vpc.publicAdmin"]
        }
      ]
      members = ["f081lpoptnbkbmf8nq9b"] # user_ids
    },
    {
      name        = "developers"
      description = "Developers"
      cloud_roles = ["k8s.cluster-api.viewer"]
      folder_roles = [
        {
          folder_name = "prod-folder"
          roles       = ["container-registry.images.pusher", "logging.reader", "monitoring.viewer"]
        }
      ]
      members = ["f081lpoptnbkbmf8nq9b"] # user_ids
    }
  ]
}
