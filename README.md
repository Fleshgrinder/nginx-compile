# nginx compile
Shell script for compiling latest [nginx](http://nginx.org) from source.

## Usage
```
cd /usr/local/src
git clone https://github.com/Fleshgrinder/nginx-compile.git
sh nginx-compile/compile.sh
```

## Features
The following features and modules are part of the resulting nginx build:

* IPv6 support
* [GZip static module](http://nginx.org/en/docs/http/ngx_http_gzip_static_module.html)
* [SSL module](http://nginx.org/en/docs/http/ngx_http_ssl_module.html)
* [SPDY module](http://nginx.org/en/docs/http/ngx_http_spdy_module.html)
* Custom OpenSSL with `enable-ec_nistp_64_gcc_128` option and heartbeat disabled.
* Latest PCRE with JIT.
* [HTTP Accept-Language module](https://github.com/Fleshgrinder/nginx_accept_language_module)
* [Google PageSpeed module](https://github.com/pagespeed/ngx_pagespeed)
* [LSB compliant SysVinit script](https://github.com/Fleshgrinder/nginx-sysvinit-script)

## Weblinks
Other repositories of interest:

- [nginx-configuration](https://github.com/Fleshgrinder/nginx-configuration)
- [nginx-session-ticket-key-rotation](https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation)
- [nginx-sysvinit-script](https://github.com/Fleshgrinder/nginx-sysvinit-script)

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>
