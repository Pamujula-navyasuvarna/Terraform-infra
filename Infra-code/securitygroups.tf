########################## security groups ##########################
resource "aws_security_group" "alb_sg" {
name = "tf-alb-sg"
description = "Allow HTTP/HTTPS from internet"
vpc_id = aws_vpc.this.id


ingress {
description = "HTTP"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}


ingress {
description = "HTTPS"
from_port = 443
to_port = 443
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}


tags = { Name = "tf-alb-sg" }
}


resource "aws_security_group" "node_sg" {
name = "tf-node-sg"
description = "Allow nodes traffic"
vpc_id = aws_vpc.this.id


ingress {
from_port = 0
to_port = 0
protocol = "-1"
security_groups = [aws_security_group.alb_sg.id]
}


egress {
from_port = 0
to_port = 0
protocol = "-1"
cidr_blocks = ["0.0.0.0/0"]
}
tags = { Name = "tf-node-sg" }
}
