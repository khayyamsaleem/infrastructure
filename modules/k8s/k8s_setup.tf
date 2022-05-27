data "digitalocean_kubernetes_cluster" "juul" {
  name = "juul"
}

provider "kubernetes" {
  host  = data.digitalocean_kubernetes_cluster.juul.endpoint
  token = data.digitalocean_kubernetes_cluster.juul.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.juul.kube_config[0].cluster_ca_certificate
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "doctl"
    args = ["kubernetes", "cluster", "kubeconfig", "exec-credential",
    "--version=v1beta1", data.digitalocean_kubernetes_cluster.juul.id]
  }
}

provider "helm" {
  kubernetes {
    host                   = data.digitalocean_kubernetes_cluster.juul.endpoint
    token                  = data.digitalocean_kubernetes_cluster.juul.kube_config[0].token
    cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.juul.kube_config[0].cluster_ca_certificate)
  }
}

provider "kubectl" {
  host                   = data.digitalocean_kubernetes_cluster.juul.endpoint
  token                  = data.digitalocean_kubernetes_cluster.juul.kube_config[0].token
  cluster_ca_certificate = base64decode(data.digitalocean_kubernetes_cluster.juul.kube_config[0].cluster_ca_certificate)
  load_config_file       = false
}
resource "helm_release" "nginx-ingress" {
  name       = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"
  namespace  = "kube-system"

  set {
    name  = "controller.publishService.enabled"
    value = true
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"

  set {
    name  = "installCRDs"
    value = true
  }
}

resource "kubectl_manifest" "letsencrypt-cluster-issuer" {
  depends_on = [
    helm_release.cert-manager,
    helm_release.nginx-ingress
  ]

  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
  namespace: cert-manager
spec:
  acme:
    # The ACME server URL
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email address used for ACME registration
    email: hello@khayyam.me
    # Name of a secret used to store the ACME account private key
    privateKeySecretRef:
      name: letsencrypt-prod
    # Enable the HTTP-01 challenge provider
    solvers:
    - http01:
        ingress:
          class: nginx
YAML
}

data "kubernetes_service" "nginx-ingress-controller" {
  depends_on = [
    data.digitalocean_kubernetes_cluster.juul
  ]
  metadata {
    name      = "nginx-ingress-controller"
    namespace = "kube-system"
  }
}

output "loadbalancer_ip" {
  description = "load balancer ip"
  value       = data.kubernetes_service.nginx-ingress-controller.status[0].load_balancer[0].ingress[0].ip
}