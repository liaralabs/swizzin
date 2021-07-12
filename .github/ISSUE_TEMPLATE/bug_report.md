---
name: Bug report
about: Report broken functionality of the swizzin toolset
title: ''
labels: ''
assignees: ''

---
<!-- Issues that do not follow the format will be automatically closed. Please make sure no headins are omitted or changed. -->
<!-- Please first consukt the project's wiki and the troubleshooting steps. you can find thise here https://swizzin.ltd/docs/guides/troubleshooting -->

## Bug description
<!-- A clear and concise description of what the bug is. -->

## Reproduction steps
Steps to reproduce the behavior:
1. Install package '...'
2. Go to '....'
3. Error '...'

## Expected behavior
<!-- A clear and concise description of what you expected to happen. -->

## Additional info
<!-- Any other context is helpulf for us. For example what hardware and provider you are using, when did you first start seeing this or what colour your cat is-->

<!-- ######################################### -->
<!-- Everything under here can be generated from your swizzin install!-->
<!-- Log into your server, run `box sysinfo`, and replace everything underneath with the output of the command-->
<!-- ######################################### -->

## Installed swizzin apps
<!-- e.g. Nginx, ffmpeg, panel -->
- App1
- App2

## Server Info
- OS: (e.g. Debian 10, Ubuntu 20.04)
- Arch: (e.g. x86, arm64)
- Hardware: <!-- Optional -->

## Swizzin version
<!-- Please run `box update`, and report whether that was succesful. Please try to reproduce your issue) again. mention the commit hash you are seeing -->

(e.g. HEAD is now at d4d151b)

## Logs and output
<!--Add any other context about the problem here. Logs, terminal output, etc. -->

(Good sources for log output could be the following: (only if they have relevant information))
- `cat /root/logs/install.log`
- `cat /root/logs/swizzin.log`
- `cat /var/logs/nginx/error.log`
- `systemctl status <app>@<(user)>`
- `journalctl -xe`

**(Please paste your code into code blocks using the triple backtick notation)**

(For logs of 50+ lines, please rehost to a paste hoster like 0bin)

 ```
 ... logs ...
 ```

