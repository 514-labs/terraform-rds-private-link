# Create a network Load Balancer
resource "aws_lb" "rds_lb" {
  name                             = var.nlb_name
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = values(data.aws_subnet.rds_subnet)[*].id
  enable_cross_zone_load_balancing = var.cross_zone_load_balancing
  tags = merge(var.default_tags, {
    Name = var.nlb_name
  })
}

# Create a single target group for the RDS cluster
resource "aws_lb_target_group" "rds_cluster_target_group" {
  name        = local.target_group_name
  port        = var.rds_cluster_details.port
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.rds_vpc.id
  target_type = "ip"

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-cluster-target-group"
  })
}

# Attach cluster writer endpoints to the target group
resource "aws_lb_target_group_attachment" "rds_cluster_target_group_attachment" {
  for_each = {
    for idx, addr in data.dns_a_record_set.rds_cluster_writer_ip.addrs : idx => {
      target_id = addr
      port      = var.rds_cluster_details.port
    }
  }

  target_group_arn = aws_lb_target_group.rds_cluster_target_group.arn
  target_id        = each.value.target_id
  port             = each.value.port

  lifecycle {
    ignore_changes = [target_id]
  }
}

# Create a single listener for the RDS cluster
resource "aws_lb_listener" "rds_cluster_listener" {
  load_balancer_arn = aws_lb.rds_lb.arn
  port              = var.rds_cluster_details.port
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rds_cluster_target_group.arn
  }

  tags = merge(var.default_tags, {
    Name = "${var.nlb_name}-cluster-listener"
  })
}