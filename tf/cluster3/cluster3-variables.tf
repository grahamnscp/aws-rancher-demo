# Global Variables: cluster3

# downstream clusters

# AWS EC2 instance type
# t3.medium     2 vcpu -  4GB mem - $0.0418/hr
# t3.large      2 vcpu -  8GB mem - $0.0835/hr
# t3.xlarge     4 vcpu - 16GB mem - $0.1670/hr
# t3.2xlarge    8 vcpu - 32GB mem - $0.3341/hr
variable "aws_instance_type_master_cluster3" {
  type = string
  default     = "t3.xlarge"
}
variable "cluster3_master_count" {
  type = string
  default = "3"
}

# Accelerated compute us-east-1:
# p3.2xlarge   $3.06     8   61 GiB  EBS Only             Up to 10 Gigabit
# g6.2xlarge   $0.9776   8   32 GiB  1 x 450 GB NVMe SSD  Up to 10 Gigabit
# g6e.2xlarge  $2.24208  8   64 GiB  1 x 450 GB NVMe SSD  Up to 20 Gigabit
# g5.2xlarge   $1.212    8   32 GiB  1 x 450 GB NVMe SSD  Up to 10 Gigabit
# g5g.2xlarge  $0.556    8   16 GiB  EBS Only             Up to 10 Gigabit
# g4ad.2xlarge $0.54117  8   32 GiB  300 GB NVMe SSD      Up to 10 Gigabit
# g4dn.2xlarge $0.752    8   32 GiB  225 GB NVMe SSD      Up to 25 Gigabit
# f1.2xlarge   $1.65     8  122 GiB  1 x 470 NVMe SSD     Up to 10 Gigabit
# trn1.2xlarge $1.34375  8   32 GiB  1 x 475 NVMe SSD     12500 Megabit
# inf1.2xlarge $0.362    8   16 GiB  EBS Only             Up to 25 Gigabit
variable "aws_instance_type_agent_cluster3" {
  type = string
  default     = "g4ad.2xlarge"
}
variable "cluster3_agent_count" {
  type = string
  default = "1"
}

# volumes
variable "volume_size_cluster3" {
  type = string
  default = "300"
}
variable "volume_size_second_disk_cluster3" {
  type = string
  default = "200"
}
#variable "volume_size_third_disk_cluster3" {
#  type = string
#  default = "200"
#}

