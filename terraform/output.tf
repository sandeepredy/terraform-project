output "instance_ips" {
    value = google_compute_instance.private-vm.network_interface[0].network_ip
}