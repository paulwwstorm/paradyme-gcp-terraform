# paradyme-gcp-terraform

&nbsp;&nbsp;&nbsp;&nbsp;The purpose of this project is to test the capabilities of the infrastructure as code tool Terraform. Our goal was to create a Kubernetes cluster inside of a Google Cloud Platform project. Once the cluster is created, we use Helm charts to deploy a Spring Cloud Data Flow and all of its related services inside the cluster. Next, we use both Helm and Terraform native resources to deploy a series of ingresses to allow external access to the services. Finally, we connect these ingresses to a DNS to allow access the Spring Cloud Data Flow and it’s services through the browser.  
\
II. Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Local installation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Terraform file structure\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
III. GCP\
&nbsp;&nbsp;&nbsp;&nbsp;A. Setting up your GCP project\
\
&nbsp;&nbsp;&nbsp;&nbsp;Because all the infrastructure we deploy through Terraform is ultimately going to be built on the Google Cloud Platform (GCP) the first step to get this process going will be creating the GCP project we want to use to deploy the infrastructure to. First start by logging into the GCP and create a new project. The only APIs necessary for this project are the Kubernetes Engine API and the Compute Engine API so search for those inside of the GCP API library and make sure they are added to the project.  

&nbsp;&nbsp;&nbsp;&nbsp;After creating the GCP project and adding the necessary APIs the next step is to create credentials for the project. Inside of the API & Services tab click the “+ create credentials” button and create service account credentials for the project. Be sure to give the account owner level permissions to the project. Once the service account has been created click on it and scroll down to add a key to the account. Choose JSON format and the key will automatically download. Move this file to inside of your Terraform folder on the same level as your main.tf file. Inside of your variables.tf add:  

&nbsp;&nbsp;&nbsp;&nbsp;variable "credentials_file" { 

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;default = "your-credential-file.json" 

&nbsp;&nbsp;&nbsp;&nbsp;} 

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
\
IV. Kubernetes\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Local installation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Cluster role bindings and clustmer management\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. Kubectl and Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;4. Kubernetes secrets and Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
V. Helm\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Pulling charts from repos\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Helm and Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. Adjusting chart values in Terraform\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
VI. Spring Cloud Data Flow\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
VII. Ingresses\
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Helm ngnix-ingress\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Terraform Kuberenetes Ingress\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
VIII. Ngnix-Ingress
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
