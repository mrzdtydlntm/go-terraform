# # Init aws service
provider "aws" {
    region = "ap-southeast-1"
    access_key = "ACCESS-KEY"
    secret_key = "SECRET-KEY"
}

# Create new instance from boilerplate image
resource "aws_instance" "website-fe-instance" {
    ami = "AMI-ID"
    instance_type = "t2.small"
    tags = {
        Name = "website-fe-network"
    }
}

# Attach security group for FE Instance
resource "aws_network_interface_sg_attachment" "website-fe-sg" {
    security_group_id    = "SG-ID"
    network_interface_id = aws_instance.website-fe-instance.primary_network_interface_id
}

# Init Cloudflare Provider
terraform {
    required_providers {
        cloudflare = {
            source  = "cloudflare/cloudflare"
            version = "~> 3.0"
        }
    }
}

provider "cloudflare" {
    api_token = "CLOUDFLARE-TOKEN"
}

# Generate subdomain portal
resource "cloudflare_record" "wbst-portal-subdomain" {
    zone_id = "ZONE-ID"
    name    = "wbst-aws-1"
    type    = "A"
    proxied = true
    ttl     = 1
    value   = aws_instance.website-fe-instance.public_ip
}

# resource "cloudflare_zone_settings_override" "wbst-portal-subdomain" {
#   zone_id = "ZONE-ID"

#   settings {
#     tls_1_3                  = "on"
#     automatic_https_rewrites = "on"
#     ssl                      = "strict"
#   }
# }

# Generate subdomain dashboard
resource "cloudflare_record" "wbst-dash-subdomain" {
    zone_id = "ZONE-ID"
    name    = "wbst-aws-2"
    type    = "A"
    proxied = true
    ttl     = 1
    value = aws_instance.website-fe-instance.public_ip
}

# resource "cloudflare_zone_settings_override" "wbst-dash-subdomain" {
#   zone_id = "ZONE-ID"

#   settings {
#     tls_1_3                  = "on"
#     automatic_https_rewrites = "on"
#     ssl                      = "strict"
#   }
# }

# Create nginx conf HTTP for portal
resource "local_file" "website-fe-nginx" {
    content  = <<EOF
upstream website-fe {
    server frontend:3000;
}

server {
    listen 80;
    server_name domain.com;

    location / {
            proxy_pass http://website-fe;
    }

    location /.well-known/acme-challenge/ {
            allow all;
            root /var/www/certbot;
            default_type "text/plain";
            try_files $uri =404;
    }
}
    EOF

    filename = "${path.module}/website-nginx/frontend.conf"
}

# Create nginx conf for dashboard
resource "local_file" "website-dash-nginx" {
    content  = <<EOF
upstream website-dash {
    server dashboard:3001;
}

server {
    listen 80;
    server_name domain2.com;

    location / {
            proxy_pass http://website-dash;
    }

    location /.well-known/acme-challenge/ {
            allow all;
            root /var/www/certbot;
            default_type "text/plain";
            try_files $uri =404;
    }
}
    EOF

    filename = "${path.module}/website-nginx/dashboard.conf"
}

# SCP the NGINX Conf to the instance
resource "null_resource" "website-fe-scp" {
    provisioner "file" {
        source      = "./website-nginx"
        destination = "/home/ubuntu"

        connection {
            type        = "ssh"
            host        = aws_instance.website-fe-instance.public_ip
            user        = "ubuntu"
            private_key = file("./ssh-key/website-keypair.pem")
            agent    = false
        }
    }  
}