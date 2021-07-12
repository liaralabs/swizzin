# About

## What are these files

These files are meant to populate some variables that allow us to gather logs for the specific application. They specify the paths and the commands to gather the output of that is going to be concatenated and sent to a pastebin provider.

## When are they being called

When `box sysinfo` is called, the system will offer to upload logs for any installed application. 

This usually happens when users are dealing with some issues they want to get help with

# Creating your own

## How to include a script for an application?

If the application is installed, it will appear in the whiptail presented to the user. If a user selects it, a script of the same name ending with `.sh` will be called from this folder.

## How to include a non-application script in the sysinfo options?

Inside of the `sysinfo` script one directory up is a function called `_make_app_choices()` which contains an array called `sysoptions` which gets called in the first `whiptail` run. Add a line which conforms to the format of the array in there, and it will show up in the whiptail. When it is selected from the whiptal, a script of the same name ending with `.sh` will be called from this folder.

## What can I use

Below are the variables that are on offer to you

### `$loguser` and `$master`

These variables have already been set so please do not change them.

`$master` will hold the expected value of the master user.

`$loguser` will hold the name of the username the logs are being collected for. Of course, this only makes sense to use in Multiuser apps.
You can use it within your script to specify paths or call things from the user's context.

### `app_sensitive=()`

Tuples of sed patterns to redact from the output in the paths and logs. The entire file that gathers the logs will be ran through this. Usage is for e.g...

``` bash
app_sensitive+=("5871" "###-RPCPORT-###")
app_sensitive+=("api: [a-zA-Z0-9]*" "api: ###-APIKEY-###")
```

### `paths=()`

Paths of files/logs to upload the content of e.g...

``` bash
paths+=(/var/log/file1.txt)
paths+=(/etc/to/log/file2.txt)
paths+=(/var/log/nginx/error.log*) #Notice the fact this is not surrounded in quotes, as that will kill the asterisk expansion, which is desired here
```

### `commands=()`

Commands to run, which will have their 2>&1 output included in the upload. e.g...

``` bash
commands+=('nginx -t')
commands+=('dmesg')
```

### `note=""`

A string to append behind each application row. e.g.

``` bash
note="Installed from PPA"
```

### `version=""`

A string of the application version if applicable. e.g.

``` bash
version="3.0, installed from PPA"
```
