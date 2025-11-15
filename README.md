I want to deploy an application.
So, I have to create a infra using terraform. 
Infra contains: 1 vpc with 2 public and private subnets in 2 availability zones. 
It should have IGW for VPC, 
1 public route table for both public subnets with are available in 2 availability zones, 
private route tables for east private subnet, 
connect IGW with public route table, 
public route table associate with public subnets, 
create nat gateway for each availability zone and place it in public subnets, 
make connections to nat gates and private route tables and associate private route tables with private subnets. 
Now I want create a cluster using KOPS with 2 master nodes and 5 worker nodes with autoscaling as 
min-3, 
max-6, 
desired-5 
Now if we want to access application we need application load balancer.


1) Create an S3 bucket for kops cluster state and enable versioning:
 aws s3api create-bucket --bucket kops-state-<your-unique-suffix> --region ${var.aws_region} --create-bucket-configuration LocationConstraint=${var.aws_region}
 aws s3api put-bucket-versioning --bucket kops-state-<your-unique-suffix> --versioning-configuration Status=Enabled

2) Export KOPS state env
 export KOPS_STATE_BUCKET=s3://kops-state-<your-unique-suffix>


3) Get VPC ID and subnet IDs after terraform apply
 VPC_ID=$(terraform output -raw vpc_id)
 PUBLIC_SUBNETS=$(terraform output -json public_subnet_ids | jq -r '.[]' | paste -sd, -)
 PRIVATE_SUBNETS=$(terraform output -json private_subnet_ids | jq -r '.[]' | paste -sd, -)


4) Create kops cluster using existing VPC & private subnets (example):
 kops create cluster --name ${var.cluster_name} --state ${KOPS_STATE_BUCKET} --cloud aws --vpc ${VPC_ID} --zones ${var.azs[0]},${var.azs[1]} --yes --node-count 5 --node-size t3.medium --master-count 2 --master-size t3.medium --networking canal


NOTE: The above sets desired node count to 5. To enable autoscaling (min=3,max=6), edit the nodes instance group:
 kops edit ig --name ${var.cluster_name} nodes
 In the YAML change spec.minSize: 3 and spec.maxSize: 6 and save.
 Then update the cluster:
 kops update cluster --name ${var.cluster_name} --yes

5) To make the k8s API accessible (or keep private) - choose topology flag or edit cluster spec accordingly.


6) For ALB integration with k8s apps, install AWS Load Balancer Controller in the cluster and annotate Service/Ingress to use the ALB or use k8s Service of type LoadBalancer which will create an ELB/NLB by default. If you prefer using the Terraform-managed ALB above, target the k8s node IPs (use externalTrafficPolicy=Local) or use NodePort/Ingress that maps to the target group.


7) Example to adjust instance group for masters to 2 replicas (HA across AZs) and workers to autoscale: create separate ig YAMLs or use kops create ig --role node --subnet ...


 Helpful tips:
 - Keep kops state in S3 with a unique bucket name.
 - Ensure you have the correct IAM permissions (kops needs AWS IAM, EC2, ELB, S3 etc.).
 - If you want kops to manage the VPC, you can skip creating VPC in Terraform and let kops create it, but since you asked to provision VPC in terraform, pass --vpc to kops.


# End of document
