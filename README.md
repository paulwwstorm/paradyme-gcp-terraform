# paradyme-gcp-terraform

&nbsp;&nbsp;&nbsp;&nbsp;The purpose of this project is to test the capabilities of the infrastructure as code tool Terraform. Our goal was to create a Kubernetes cluster inside of a Google Cloud Platform project. Once the cluster is created, we use Helm charts to deploy a Spring Cloud Data Flow and all of its related services inside the cluster. Next, we use both Helm and Terraform native resources to deploy a series of ingresses to allow external access to the services. Finally, we connect these ingresses to a DNS to allow access the Spring Cloud Data Flow and it’s services through the browser.  
\
II. Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Local installation\
&nbsp;&nbsp;&nbsp;&nbsp;To install Terraform on the local machine, the installation instructions can be found in https://learn.hashicorp.com/tutorials/terraform/install-cli.
\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Terraform file structure\
&nbsp;&nbsp;&nbsp;&nbsp;When setting up Terraform, create a folder in which Terraform would derive the configuration for the infrastructure from.  The core file in the Terraform directory would be the main.tf file.  

&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
III. GCP\
&nbsp;&nbsp;&nbsp;&nbsp;A. Setting up your GCP project\
\
&nbsp;&nbsp;&nbsp;&nbsp;Because all the infrastructure we deploy through Terraform is ultimately going to be built on the Google Cloud Platform (GCP) the first step to get this process going will be creating the GCP project we want to use to deploy the infrastructure to. First start by logging into the GCP and create a new project. The only APIs necessary for this project are the Kubernetes Engine API and the Compute Engine API so search for those inside of the GCP API library and make sure they are added to the project.  

&nbsp;&nbsp;&nbsp;&nbsp;After creating the GCP project and adding the necessary APIs the next step is to create credentials for the project. Inside of the API & Services tab click the “+ create credentials” button and create service account credentials for the project. Be sure to give the account owner level permissions to the project. Once the service account has been created click on it and scroll down to add a key to the account. Choose JSON format and the key will automatically download. Move this file to inside of your Terraform folder on the same level as your main.tf file. Inside of your variables.tf add:  

```
"credentials_file" { 

  default = "your-credential-file.json" 

} 
```

&nbsp;&nbsp;&nbsp;&nbsp;Once this is complete, the initial set-up for your GCP project should be complete. If at any point you are struggling with Kubernetes cluster role bindings make sure the service account associated with the “client_email” within your credentials JSON file has owner level permission inside of your GCP project. (Permission can be changed by going to the IAM tab within your GCP project and locating the correct service account). 

&nbsp;&nbsp;&nbsp;&nbsp;After setting up your GCP project it is a good idea to install gcloud on your computer as it will be necessary to run some commands from the command line. Here is the documentation for installing gcloud commands on your computer: https://cloud.google.com/sdk/docs/quickstart. 

&nbsp;&nbsp;&nbsp;&nbsp;B. GCP elements within Terraform\
\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Now we can look at the GCP related elements within the main.tf file itself. The first one is the Google provider which allows Terraform connect to your GCP project using the credentials file we created earlier. To make sure the provider runs without issue make sure that the credentials_file, project, region, and zone have all be set within the variables.tf file. The project variable can simply be set to the name of your GCP project. The region and zone can be set at your discretion although it is recommended to choose resources physically close to your location.  

&nbsp;&nbsp;&nbsp;&nbsp;Within our project we want to make sure that our Google Kuberenetes Engine cluster was kept separate from the rest of GCP project able to access and use its own resources without interfering with anything else that might be on the project. The easiest way to do that is to create a subnetwork on a Virtual Private Cloud within the project. Luckily, Terraform provides us with the google_compute_network “vpc” and “subnetwork” resources. First, we create the VPC and then we create a subnetwork within that VPC which is why the subnetwork resource requires the “network” variable to be set to the name of the VPC resource created before it.  

&nbsp;&nbsp;&nbsp;&nbsp;The last Google resource we want to create before getting started with our GKE cluster is the firewall. By creating a firewall within Terraform we ensure that before our cluster even goes it has the necessary infrastructure in place to protect the VPC that we just created.C. 

&nbsp;&nbsp;&nbsp;&nbsp;C. Networking and Google DNS

&nbsp;&nbsp;&nbsp;&nbsp;The final major piece of Google infrastructure we will be using inside of this project is Google’s DNS service. We will use the DNS to provide external access to our services through the browser.  So the first step in this process is to set up a domain! If you would like to create a free domain for the purposes of testing you can use this website: https://www.freenom.com. After creating your free domain navigate to Network Services > Cloud DNS within your GCP project. Click “create zone”. Name the zone whatever you would like and copy in the domain you got from freenom into the DNS name. Once your zone is created click on it and you should see four googledomains. Find your domain and click “Manage Domain” > “Management Tools” > “Nameservers”. Copy the four googledomains into the first four name server spaces. With this your domain is connected to your GCP project.  

&nbsp;&nbsp;&nbsp;&nbsp;To make sure that Ingresses created within our Terraform file are connected to the DNS zone we just created we can add an A Record  using the “google_dns_record_set” “a” resource. For the “name” variable enter * (to ensure that all of your different services can be made available) followed by “.domain-name.com.” (be sure to include the trailing period). The “managed_zone” is simply the name of the DNS zone we just created on our project. And finally the rrdatas will be the IP address assigned to the NGINX Ingress we created earlier within our main.tf file. Google will use this IP address to funnel traffic from the domain to the ingress which will then re-direct to the specific services in your GKE cluster.  

&nbsp;&nbsp;&nbsp;&nbsp;D. GKE (Google Kubernetes Engine)

&nbsp;&nbsp;&nbsp;&nbsp;A provider would be created for kubernetes and kubectl to set up the resources to create the kubernetes cluster.  Examples of the kubernetes and kubectl providers would be:

```
provider "kubernetes" {
  config_context_cluster = google_container_cluster.default.name
  load_config_file       = false
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
}

provider "kubectl" {
  config_context_cluster = google_container_cluster.default.name
  load_config_file       = false
  host                   = "https://${google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.default.master_auth.0.cluster_ca_certificate)
}
```

When those providers have been initialized in the main.tf file, resources that are generated from the providers can be configured as well.  

&nbsp;&nbsp;&nbsp;&nbsp;Kubernetes cluster role bindings would define the role and permissions that the user would have with the service project and therefore the GKE.  An example of a kubernetes cluster role binding would be:

```
resource "kubernetes_cluster_role_binding" "role_binding" {
  metadata {
    name = "terraform-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "cluster-admin"
  }
  subject {
    kind      = "User"
    name      = "617377547426-compute@developer.gserviceaccount.com"
    api_group = ""
    namespace = "default"
  }
  
}
```

&nbsp;&nbsp;&nbsp;&nbsp;Terraform sometimes does not have the equivalent resource to replicate some of the Kubernetes yaml files.  To work around this, the kubectl resource can be used to apply the yaml files.  First a directory for the yaml files would need to be created in the Terraform directory, typically it would be named kubernetes.  Then the yaml files that do not have a Terraform equivalent would be added into the directory, and they would be applied by the resources below.

```
data "kubectl_filename_list" "manifests" {
  pattern = "./kubernetes/*.yaml"
}
 
resource "kubectl_manifest" "kubernetes_cert" {
    count = length(data.kubectl_filename_list.manifests.matches)
    yaml_body = file(element(data.kubectl_filename_list.manifests.matches, count.index))
}
```

&nbsp;&nbsp;&nbsp;&nbsp;Kubernetes secrets can be added to services ran under GKE through the kubenetes_secret resource.  The secret will allow passwords to be added to the services, for example, in this instance a username and password was added to the Prometheus service.  To do this, an htpasswd file was generated online and added to the Terraform directory.  After adding that, the kubernetes_secret resource was added to main.tf, looking like below:

```
resource "kubernetes_secret" "basic-auth" {
  metadata {
        name      = "basic-auth"
        namespace = "default"
      }
  data = {
    "auth" = file("./auth")
  }
}
```

That secret could now be used on the the various services in the GKE cluster.  This secret is added to the Prometheus service by adding it to the Prometheus Ingress by use of annotations.

\
IV. Helm\
&nbsp;&nbsp;&nbsp;&nbsp;A. Helm Charts\
&nbsp;&nbsp;&nbsp;&nbsp;For all of the services we want to create on our cluster we are going to Helm charts. Helm charts are files that help define, create and manage Kubernetes applications. This saves us from having to create and define each service individually. You can read more about helm charts [here](https://helm.sh/). 

&nbsp;&nbsp;&nbsp;&nbsp;For things like updating dependencies you will need to install Helm locally, [here](https://helm.sh/docs/intro/install/) is a guide on how to do that.  

&nbsp;&nbsp;&nbsp;&nbsp;The two primary Helm charts we will be using are the NGINX Ingress Helm chart and the Spring Cloud Data Flow Helm Chart. The Spring Cloud Data Flow itself contains many different services which also have their own Helm charts. We have included versions of both the NGINX Ingress Helm chart and the Spring Cloud Data Flow Chart inside of the repository. It may be necessary to update the dependencies for these charts. To do so, simple navigate into the charts folder and run the command “helm dependency update” from the command prompt. If you would like to download the most recent version of the Helm charts the NGING Ingress Helm chart can be found [here](https://github.com/kubernetes/ingress-nginx/tree/master/charts/ingress-nginx) and the Spring Cloud Data Flow Helm chart can be found [here](https://github.com/helm/charts/tree/master/stable/spring-cloud-data-flow). 

&nbsp;&nbsp;&nbsp;&nbsp;B. Helm Charts in Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;Luckily for us, Terraform provides us with a tool to install Helm charts within our main.tf file. That tool is the “helm” provider. As you can see, all the helm provider needs is the GKE cluster information and credentials returned from Google. After we set up the provider for each Helm chart we want to install on our cluster we can create a “helm_release” resource. Accordingly, we have two helm_resources in this main.tf file, one for the NGINX Ingress and one for Spring Cloud Data Flow. For each helm_resource make sure the “provider” is set to helm.your_provider (“your_provider” being whatever “alias” you declared in your “helm” provider resource). And the “chart” variable should be set to the location of the Helm chart you wish to install. 

&nbsp;&nbsp;&nbsp;&nbsp;Upon occasion it will be necessary to overwrite the values in the values.yaml file of a given Helm chart. For example, for this deployment we wanted to use Kafka for our Spring Cloud Data Flow and not RabbitMQ, which is the default. The easiest way to do this is by setting the “values” parameter on the “helm_release resource. The basic syntax looks like this: 
```
values = [ 

    <<EOF     

    EOF 

  ] 
```

 

&nbsp;&nbsp;&nbsp;&nbsp;For example, to install Kafka instead of RabbitMQ we set the values like so: 

 
```
  values = [ 

    <<EOF 

      kafka: 

        enabled: true 

        persistence: 

          size: 20Gi 

      rabbitmq: 

        enabled: false 

    EOF 

  ] 
```
 
&nbsp;&nbsp;&nbsp;&nbsp;C. Creating Promethues Login\
&nbsp;&nbsp;&nbsp;&nbsp;Inside of our "helm_release" "nginx-ingress" you will notice inside of the values parameter we set some Prometheus related values. Because Prometheus itself does not come with the ability to add a username and password login, we the NGINX Ingress itself to restrict access to the Prometheus service. The second part of this equation is the "kubernetes_secret" "basic-auth" resource which allows us to create an auth file with a username and password to grant access to the Prometheus service. The final part of creating a login for the Promethues services in include in section VII regarding the kubernetes_ingress resource. The contents for a new auth file can be generated [here](https://hostingcanada.org/htpasswd-generator/) using any username and password combination you like. You can simply replace the content of the existing auth file with the SHA1 code generated from the website.  

\
V. Spring Cloud Data Flow\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
\
&nbsp;&nbsp;&nbsp;&nbsp;Spring Cloud Data Flow is generated through the Spring Cloud Data Flow Helm Chart.  Adding the Helm Chart to the Terraform directory would allow Terraform to locate it when specified to be used in the main.tf file.  The Spring Cloud Data Flow Helm Chart has multiple subcharts within it, including Grafana and Prometheus.  These would generate the Grafana and Prometheus services as well when the Spring Cloud Data Flow service is generated.\
\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
&nbsp;&nbsp;&nbsp;&nbsp;The Spring Cloud Data Flow Helm Chart would have to be pulled from the helm chart repo by performing a helm pull stable/spring-cloud-data-flow.  The corresponding folder for the chart would then be copied into the Terraform directory\
\
VI. Kubernetes Ingresses\
&nbsp;&nbsp;&nbsp;&nbsp;In addition to the NGINX Ingress we installed using Helm charts we also created a separate Ingress for the Prometheus service. We do this using the "kubernetes_ingress" "scdf_prometheus_ingress" resource. The first thing you will notice is these annotations:  

``` 

   annotations = { 

      "kubernetes.io/ingress.class" = "nginx" 

      "nginx.ingress.kubernetes.io/auth-type" = "basic" 

      "nginx.ingress.kubernetes.io/auth-secret" = "basic-auth" 

      "nginx.ingress.kubernetes.io/auth-realm" = "Authentication Required - prometheus" 

      "cert-manager.io/cluster-issuer" = "letsencrypt-staging" 

    } 

``` 

&nbsp;&nbsp;&nbsp;&nbsp;This is the last part of our three step solution to create a username and password login for our Prometheus service.  

&nbsp;&nbsp;&nbsp;&nbsp;Another thing to note is the “spec: backend: service_name” which must be set to the name of the service once it is created on the cluster. You can find this name on the GCP console after you have deployed the Spring Cloud Data Flow using the Helm chart. The same name should be used for the “spec: rule: http: path: backend: service_name” parameter. The only other important parameters her are the “spec: rule: host” and the “spec: tls: hosts” which should be set to “prometheus.your-domain.com” (Although you could theoretically put whatever name you want in front of “your-domain.com”). 
\
VII. Nginx-Ingress\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
\
&nbsp;&nbsp;&nbsp;&nbsp;The Nginx-Ingress Helm Chart would create the Nginx-Ingress controller that would be the load-balancer in which the Spring Cloud Data Flow services can connect to.  Through this controller, the services would be able to be accessed from an outside user by searching the urls corresponding to the ingress destinations.\
\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
&nbsp;&nbsp;&nbsp;&nbsp;The Nginx-Ingress Helm Chart would have to be pulled from the helm chart repo by performing a helm pull stable/nginx-ingress.  The corresponding folder for the chart would then be copied into the Terraform directory
