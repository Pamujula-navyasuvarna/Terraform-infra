########################## vpc.tf ##########################
resource "aws_vpc" "this" {
cidr_block = var.vpc_cidr
enable_dns_hostnames = true
enable_dns_support = true
tags = {
Name = "tf-kops-vpc"
}
}


# Internet Gateway
resource "aws_internet_gateway" "igw" {
vpc_id = aws_vpc.this.id
tags = { Name = "tf-kops-igw" }
}


# Public subnets (2 AZs)
resource "aws_subnet" "public" {
for_each = { for idx, cidr in var.public_subnets : idx => cidr }
vpc_id = aws_vpc.this.id
cidr_block = each.value
availability_zone = var.azs[tonumber(each.key)]
map_public_ip_on_launch = true
tags = {
Name = "tf-public-${each.key}"
}
}

# Private subnets (2 AZs)
resource "aws_subnet" "private" {
for_each = { for idx, cidr in var.private_subnets : idx => cidr }
vpc_id = aws_vpc.this.id
cidr_block = each.value
availability_zone = var.azs[tonumber(each.key)]
tags = {
Name = "tf-private-${each.key}"
}
}


# Public route table
resource "aws_route_table" "public" {
vpc_id = aws_vpc.this.id
tags = { Name = "tf-public-rt" }
}


resource "aws_route" "public_internet_access" {
route_table_id = aws_route_table.public.id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw.id
}

# Associate public subnets with public route table
resource "aws_route_table_association" "public_assoc" {
for_each = aws_subnet.public
subnet_id = each.value.id
route_table_id = aws_route_table.public.id
}


########################## nat.tf ##########################
# Allocate EIP & NAT Gateway for each AZ (placed in public subnets)
resource "aws_eip" "nat_eip" {
for_each = aws_subnet.public
vpc = true
tags = { Name = "tf-nat-eip-${each.key}" }
}


resource "aws_nat_gateway" "nat" {
for_each = aws_subnet.public
allocation_id = aws_eip.nat_eip[each.key].id
subnet_id = each.value.id
depends_on = [aws_internet_gateway.igw]
tags = { Name = "tf-nat-${each.key}" }
}

# Private route tables (one per AZ/private subnet) with route to NAT in same AZ
resource "aws_route_table" "private" {
for_each = aws_subnet.private
vpc_id = aws_vpc.this.id
tags = { Name = "tf-private-rt-${each.key}" }
}


resource "aws_route" "private_nat_route" {
for_each = aws_subnet.private
route_table_id = aws_route_table.private[each.key].id
destination_cidr_block = "0.0.0.0/0"
nat_gateway_id = aws_nat_gateway.nat[each.key].id
}


# Associate private subnets with their private route table
resource "aws_route_table_association" "private_assoc" {
for_each = aws_subnet.private
subnet_id = each.value.id
route_table_id = aws_route_table.private[each.key].id
}

