variable "vm_image" {
  description = "Path or URL to the Ubuntu cloud image (OVA)"
  type        = string
  default     = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.ova"
}

variable "hostonly_interface" {
  description = "Name of the VirtualBox host-only interface (e.g. vboxnet0)"
  type        = string
  default     = "vboxnet0"
}

variable "student_ssh_public_key" {
  description = "SSH public key for the ansible user (set via TF_VAR_student_ssh_public_key)"
  type        = string
}
