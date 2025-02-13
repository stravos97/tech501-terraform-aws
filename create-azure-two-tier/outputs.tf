output "vm_public_ip" {
  value       = module.compute_app.vm_public_ip
  description = "Public IP address of the VM"
}
