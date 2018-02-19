#
# __description __ = "Definition of reusable Terraform code to deploy an Autoscaling Group with
#                    "Security Group, Launch Configuration and Elastic Load Balancer in AWS"
#
# __credits__ = "https://blog.gruntwork.io/how-to-create-reusable-infrastructure-with-terraform-modules-25526d65f73d"

# --- Security Group --- #
# ---------------------- #

resource "aws_security_group" "frontend-webserver_sg" {
  name        = "frontend-webserver_sg"
  description = "Allow inbound traffic to webservers"
  vpc_id      = "${var.aws_vpc}"
}

resource "aws_security_group_rule" "frontend-webserver_sgr_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.frontend-webserver_sg.id}"
}

resource "aws_security_group_rule" "frontend-webserver-sgr_in_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.frontend-webserver_sg.id}"
}

resource "aws_security_group_rule" "frontend-webserver-sgr_out_any" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.frontend-webserver_sg.id}"
}

# --- AMI Lookup --- #
# ------------------ #

data "aws_ami" "Amazon-Linux-2-LTS" {
  most_recent = true

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
}

# --- Key Pair --- #
# ---------------- #

resource "aws_key_pair" "frontend_webserver_kp" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

# --- Launch Configuration --- #
# ---------------------------- #

resource "aws_launch_configuration" "frontend_webserver_lc" {
  name_prefix     = "frontend_webserver_lc-"
  image_id        = "${data.aws_ami.Amazon-Linux-2-LTS.id}"
  instance_type   = "${var.instance_type}"
  key_name        = "${aws_key_pair.frontend_webserver_kp.id}"
  security_groups = ["${aws_security_group.frontend-webserver_sg.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

# --- List of Availability Zones of region --- #
# -------------------------------------------- #

data "aws_availability_zones" "all" {}

# --- Elastic Load Balancer --- #
# ----------------------------- #

resource "aws_elb" "frontend_webserver_elb" {
  name                        = "frontend-webserver-elb"
  availability_zones          = ["${data.aws_availability_zones.all.names}"]
  security_groups             = ["${aws_security_group.frontend-webserver_sg.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  "listener" {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    interval            = "${var.elb_interval}"
    target              = "${var.elb_health_target}"
    timeout             = "${var.elb_timeout}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
  }

  tags {
    Name = "frontend_webserver_elb"
  }
}

# --- Auto Scaling Group --- #
# -------------------------- #

resource "aws_autoscaling_group" "frontend_webserver_asg" {
  launch_configuration = "${aws_launch_configuration.frontend_webserver_lc.id}"
  availability_zones   = ["${data.aws_availability_zones.all.names}"]

  max_size         = "${var.asg_max_size}"
  min_size         = "${var.asg_min_size}"
  desired_capacity = "${var.asg_cap}"

  load_balancers            = ["${aws_elb.frontend_webserver_elb.id}"]
  health_check_type         = "ELB"
  health_check_grace_period = "${var.hcl_grace}"

  vpc_zone_identifier = ["${var.vpc_zone_identifier}"]
  force_delete        = true
}
