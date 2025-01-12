# Global Variables: cluster3

# downstream clusters
#
# AWS EC2 instance type
# t3.medium     2 vcpu -  4GB mem - $0.0418/hr
# t3.large      2 vcpu -  8GB mem - $0.0835/hr
# t3.xlarge     4 vcpu - 16GB mem - $0.1670/hr
# t3.2xlarge    8 vcpu - 32GB mem - $0.3341/hr
variable "aws_instance_type_cluster3" {
  type = string
  default     = "t3.xlarge"
}
variable "aws_instance_type_node_cluster3" {
  type = string
  default     = "t3.xlarge"
}
# downstream test cluster nodes
variable "cluster3_node_count" {
  type = string
  default = "3"
}
variable "cluster3_agent_count" {
  type = string
  default = "2"
}
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
