resource "aws_security_group" "rds" {
  name   = "${var.project}-rds-sg-${var.environment}"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project}-rds-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project}-db-subnet-${var.environment}"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project}-db-subnet-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_instance" "postgres" {
  identifier        = "${var.project}-db-${var.environment}"
  engine            = "postgres"
  engine_version    = "15"
  instance_class    = var.db_instance_class
  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  skip_final_snapshot     = var.environment != "production"
  deletion_protection     = var.environment == "production"
  backup_retention_period = var.environment == "production" ? 7 : 1
  multi_az                = var.environment == "production"
  publicly_accessible     = false

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

