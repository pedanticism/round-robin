resource "aws_lb" "alb" {
  name               = "alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_default_subnet.default_az1.id, 
    aws_default_subnet.default_az2.id
  ]
  enable_deletion_protection = false


  tags = {
    Environment = "production"
  }
}

resource "aws_alb_listener" "alb_listener" {  
  load_balancer_arn = aws_lb.alb.arn  
  port              = "80"  
  protocol          = "HTTP"
  
  default_action {    
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"  
  }
}

resource "aws_alb_listener_rule" "listener_rule" {
  depends_on   = [aws_alb_target_group.alb_target_group]  
  listener_arn = aws_alb_listener.alb_listener.arn  
  action {    
    type             = "forward"    
    target_group_arn = aws_alb_target_group.alb_target_group.id
  }   
  condition {    
    field  = "path-pattern"    
    values = ["/"]  
  }
}

resource "aws_alb_target_group" "alb_target_group" {  
  name     = "ALB-target-group"  
  port     = "3000"  
  protocol = "HTTP"  
  vpc_id   = aws_default_vpc.default_vpc.id   
}

