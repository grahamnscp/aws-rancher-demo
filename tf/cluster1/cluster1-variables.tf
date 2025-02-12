# Global Variables: cluster1

# downstream clusters
#
# AWS EC2 instance type
# t3.medium     2 vcpu -  4GB mem - $0.0418/hr
# t3.large      2 vcpu -  8GB mem - $0.0835/hr
# t3.xlarge     4 vcpu - 16GB mem - $0.1670/hr
# t3.2xlarge    8 vcpu - 32GB mem - $0.3341/hr
variable "aws_instance_type_cluster1" {
  type = string
  default     = "t3.2xlarge"
}
# downstream test cluster nodes
variable "cluster1_node_count" {
  type = string
  default = "3"
}
variable "volume_size_cluster1" {
  type = string
  default = "200"
}
variable "volume_size_second_disk_cluster1" {
  type = string
  default = "300"
}
# needed if using portworx
#variable "volume_size_third_disk_cluster1" {
#  type = string
#  default = "200"
#}
