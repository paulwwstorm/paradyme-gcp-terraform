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
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. GCP project creation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Local installation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. Service accounts and permissions\
&nbsp;&nbsp;&nbsp;&nbsp;B. Networking\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. VPC and Firewall\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Google DNS\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;i. Domain creation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;ii. DNS zone creation\
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;iii. Creating a records in Terraform\
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
IX. Ngnix-Ingress
&nbsp;&nbsp;&nbsp;&nbsp;A. Implementation\
&nbsp;&nbsp;&nbsp;&nbsp;B. Tools\
\
