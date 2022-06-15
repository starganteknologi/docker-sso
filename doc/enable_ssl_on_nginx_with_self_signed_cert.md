# Enable SSL on NGINX with self signed certificate

## create self signed cert 
[how to create self signed certificate](create_self_sign_certificate_with_local_ca.md)

### generate dhparam

``` shell
openssl dhparam -out cert/dhparam.pem 2048
```

## configure NGINX

### create a new configuration file ```nginx\config\ssl-params.conf```

``` conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-SHA384;
ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
ssl_session_timeout 10m;
ssl_session_cache shared:SSL:10m;
ssl_session_tickets off; # Requires nginx >= 1.5.9
# ssl_stapling on; # Requires nginx >= 1.3.7
# ssl_stapling_verify on; # Requires nginx => 1.3.7
resolver 8.8.8.8 8.8.4.4 192.168.1.1 valid=300s; # add with your local dns
resolver_timeout 5s;
add_header X-Frame-Options DENY;
add_header X-Content-Type-Options nosniff;
add_header X-XSS-Protection "1; mode=block";
add_header Strict-Transport-Security "max-age=63072000; includeSubdomains";
```

### create a new configuration file ```nginx\config\self-signed.conf```

``` conf
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/certs/nginx-selfsigned.key;
```

### create a new configuration file ```nginx\config\nginx.conf```

``` conf
server {
    # SSL configuration
    listen 443 ssl http2 default_server;
    listen [::]:443 ssl http2 default_server;
    include conf.d/self-signed.conf;
    include conf.d/ssl-params.conf;

	root /var/www/sso/public;

    server_name sso.stargan.local;

    location / {
        # try to serve file directly, fallback to index.php
        try_files $uri /index.php$is_args$args;
    }

    location ~ ^/index\.php(/|$) {
        fastcgi_pass php:9000;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT $realpath_root;
        internal;
    }

    # return 404 for all other php files not matching the front controller
    # this prevents access to other php files you don't want to be accessible.
    location ~ \.php$ {
        return 404;
    }

    error_log /var/log/nginx/project_error.log;
    access_log /var/log/nginx/project_access.log;
}
```