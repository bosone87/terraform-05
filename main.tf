module "vpc_dev" {
  source   = "./vpc_dev"
  env_name     = "develop"
  subnets = [
    { zone = "ru-central1-a", 
      cidr = "10.0.1.0/24" }
    ]
}
module "vpc_prod" {
  source       = "./vpc_dev"
  env_name     = "production"
  subnets = [
    { zone = "ru-central1-a", 
      cidr = "10.0.1.0/24" },
    { zone = "ru-central1-b", 
      cidr = "10.0.2.0/24" },
    { zone = "ru-central1-c", 
      cidr = "10.0.3.0/24" },
  ]
}

module "test-vm" {
  source          = "git::https://github.com/udjin10/yandex_compute_instance.git?ref=main"
  env_name        = "develop"
  network_id      = module.vpc_dev.network_id
  subnet_zones    = ["ru-central1-a"]
  subnet_ids      = [ module.vpc_dev.subnet_id ]
  instance_name   = "web"
  instance_count  = 1
  image_family    = "ubuntu-2004-lts"
  public_ip       = true
  
  metadata = {
      user-data          = data.template_file.cloudinit.rendered
      serial-port-enable = 1
  }
}

data "template_file" "cloudinit" {
 template = file("./cloud-init.yml")
  vars = {
    username         = "ubuntu"
    ssh_public_key   = file("~/.ssh/id_ed25519.pub")
  }
}

provider "vault" {
 address = "http://127.0.0.1:8200"
 skip_tls_verify = true
 token = "education"
}
data "vault_generic_secret" "vault_example" {
 path = "secret/example"
}

output "vault_example" {
 value = data.vault_generic_secret.vault_example.data
 sensitive = true
}
resource "vault_mount" "kvv1" {
  path        = "kvv1"
  type        = "kv"
  options     = { version = "1" }
}

resource "vault_kv_secret" "secret" {
  path = "${vault_mount.kvv1.path}/secret"
  data_json = jsonencode(
  {
    user1 = "pass1",
    user2 = "pass2"
  })
}