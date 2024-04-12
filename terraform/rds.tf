
resource "aws_db_instance" "main" {
  identifier        = "production-db"
  engine            = "postgres"
  engine_version    = "16.2"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20
  storage_type      = "gp2"

  db_name                     = "productiondb"
  username                    = "root"
  manage_master_user_password = true
  vpc_security_group_ids      = [aws_security_group.rds.id]
  db_subnet_group_name        = aws_db_subnet_group.main.name
  publicly_accessible         = true
  skip_final_snapshot         = true
}
