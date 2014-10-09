# nginx compile
Shell script collection for compiling latest [nginx](http://nginx.org/) from
source. With my personal compile options, feel free to fork this repository and
alter it to your needs. If you can help me to improve (e.g. better performance
with some flags) my scripts please open an issue or create a pull request.

## Installation
Check the `config.sh` file for configuration options.

```
git clone https://github.com/Fleshgrinder/nginx-compile.git
sh nginx-compile/compile.sh openssl
```

You may want to change the configure options for nginx in `compile.sh` to meet
your needs.

## License
> This is free and unencumbered software released into the public domain.
>
> For more information, please refer to <http://unlicense.org>

## Weblinks
Other repositories of interest:

- [nginx-configuration](https://github.com/Fleshgrinder/nginx-configuration)
- [nginx-session-ticket-key-rotation](https://github.com/Fleshgrinder/nginx-session-ticket-key-rotation)
- [nginx-sysvinit-script](https://github.com/Fleshgrinder/nginx-sysvinit-script)
