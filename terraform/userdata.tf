

# Render a multi-part cloud-init config making use of the part
# above, and other source files
data "local_file" "install_sh" {
    filename = "${path.module}/install.sh"
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = data.local_file.install_sh.content
  }
}