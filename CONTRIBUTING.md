# Contributing guidelines
Here are a couple things to take into account when contributing to swizzin.

There is a large amount of further documentation and guidance available in our docs https://swizzin.ltd/dev/. You are expected to familiarise yourself with the documentation and the code.

In case anything is not clear, we're always happy to explain and teach why/how these things are done; feel free to come talk to us in our Discord.

## Merging against the `develop` branch
As we use the git flow, please make sure to make your PRs from the `develop` branch, and target the `develop` branch for the PRs.

Changes will make it to the master in releases.

## Requirements for consideration
We expect the following criteria from a PR. You're more than welcome to ask us how to achieve any of these that you are not familiar with, and we'll be happy to help.
- A completed checklist
- No `shellcheck`/`shfmt` errors or warnings.
- A proof of the changes being tested

You are welcome to submit PRs that do not fit this spec, but they are required to be marked as Draft PRs and preferrably pre-pended with `WIP: ` at the beginning of the PR title. If that is the case, please mention what your outstanding TODOs for the PR are.

## Editor plugins and tooling
Please note that Extensions for VSCode should pop up as "recommended extensions", so just open it up and install them in one click!

### Required
Please make sure that you have the following plugins and tools installed and working correctly.
- `shellcheck` [VSCode Plugin](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck) and [Binary](https://www.shellcheck.net/) (**version 0.7.1 or higher**)
  - If you are not using VS Code with the plugin above, please make sure to catch **anything** that `shellcheck` does not like.
  - Wherever you deem appropriate, add `#shellcheck disable=...` _inline_ to suppress the warnings.
- `shell-format` [VSCode Plugin](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format) (auto-installs binary) and [Binary](https://github.com/mvdan/sh)
  - If you are not using VS Code with the plugin above, please make sure to apply formatting with the flags mentioned in [`settings.json`](.vscode/settings.json)

### Suggested
These are just some super useful ones we really like that you should give a shot
- `shellman` [VSCode Plugin](https://marketplace.visualstudio.com/items?itemName=Remisa.shellman)
    - It's just a collection of super useful snippets
- `Bash IDE` [VSCode Plugin](https://marketplace.visualstudio.com/items?itemName=mads-hartmann.bash-ide-vscode)
    - Offers a lot of the Intellisense features that make VSCode worth using


## Directories and files
- Please use `/opt` to install any new software. **Avoid using home directories to install application binaries/source**
- When creating configuration for users, please add it to an appropriate folder under `~/.config/` when possible
- Please make sure to put any necessary code output into the default log files for swizzin, (i.e. `swizzin.log` and `install.log` under `/root/logs`) *including* the `stderr`
- Make sure to create `.lock` files for your application under `/install/`
  - Record any application information that might need to be dynamically retrieved into the .lock file above.

## Bash code styleguide

### Formatting
We are a 4-space gang. Please make sure to run your code through `shfmt` with the right flags specified. Check the first chapter here.

### Shellcheck
Please use `shellcheck` and its IDE plugins and resolve any warnings for the code you have contributed.

### Code re-use
Please familiarise yourself with the functions available under `sources/functions` as they handle a large amount of steps you might need to do manually.

A list of the files that are included on a `box` or a `setup.sh` by default are in `sources/globals.sh`

Whenever you are contributing code that might be generalized and useful for other applications, please add the functions to this location. When doing so, please give a quick comment into the file on what the purpose and possible return output is. e.g:
```bash
# Retrieves all users that are managed by swizzin
# Returns usernames separated by newline
```

#### Snippets
We have made a couple snippet definitions in the `.vscode` folder that should be getting loaded into your project whenever you open the workspace.

These should cover most of the functions included in `globals.sh`, but feel free to add yours if you have any suggestions

### Return codes
Please use `exit 1` or `return 1` when handling exiting due to some run-time errors

### Codename-based logic
When making logic based on distribution codenames, please structure it in such a way that introduces as little need for maintenance in the future as possible.

A practical example for this is handling packages that are no longer packaged for newer LTS releases. In such scenarios, please make it so that the "default" behaviour is for newer LTS releases, and the older LTS releases are treated as the outliers. e.g.:
```bash
if [[ $codename =~ ("buster"|"stretch") ]]; then
  mcrypt=php-mcrypt
else
  mcrypt=
fi

# Apt install line which has $mcrypt in the package list

```
In this example, the default (`else`) behaviour triggers for current releases, and only the old ones have the modified behaviour

## Handling interactivity
Please make sure your scripts are compatible with the custom/unattended installation options through environment variables. This means that there should be a scenario in your script, where no interaction is necessary if necessary variables are available before the script started.

Please stick to the following:
- Pre-fix your variables with the name of the application to prevent collisions, e.g. `$APPLICATION_VARIABLE`
- Ensure your script is checking the existance of the variable before triggering anything interactive, so that the scripts can skip over things if they are supplied through options.
  - e.g. `if [[ -z $APPLICATION_VARIABLE ]]; then read $APPLICATION_VARIABLE; fi`
  - e.g. `while [[ -z $APPLICATION_VARIABLE ]]; do [...] APPLICATION_VARIABLE=$verified-value [...] ; done`
- Appropriately document the varaibles in the docs repo

## APT handling
We have developed our own internal set of functions for handling `apt` packages in a predictable and uniform way. In the event any of these functions encounter an error, they will (with default behaviour) ensure the rest of the script will not continue. Please use the following functions and see the available options. **Refrain from calling the raw apt equivalents of the functions below.** 

### Functions
* Exported and box-wide available functions. By default, the functions perform `apt-get update`s for you if the database is too old (more than 1h), runs sanity checks before installs, and checks logs for errors so the script is killed in case something went wrong. These can all be overrode with the options below.
  * `apt_install [options] $1, $2, $3 ... [options]`
  * `apt_remove [options] $1, $2, $3 ... [options]`
  * `apt_autoremove`
  * `apt_upgrade [options]`
  * `apt_update [options]`
* Non-exported functions which need a `source` or a `. .../apt`. Please consult the `sources/functions/apt` file to see what they do and how they work.
  * `get_candidate_version`
  * `_get_apt_last_log`
  * `check_installed`
  * ... and a couple others

**FYI the default behaviour in most of the functions is to not issue `apt update` in case the last update was within an hour** with the exception of `apt_update`, which will always perform an update. It is therefore fine to issue an `apt_update` and an `apt_install`, as the update will only run once.

### Options
The following options can be used with any of the exported functions above to override their default behaviour.

* `--interactive`
  * Run the installation stdout in the forefront and allow any end-user interaction if necessary
  * WARNING: This is not yet fully tested
* `--skip-check`
  * Skips integrity checks during the command such as `dpkg` lock checking, `apt --simulate`, and a couple others.
* `--ignore-errors`
  * Allows script to continue in case an error was encountered, instead of killing the job script by default
* `--purge`
  * _Only for `apt_remove`_: performs the removal with the `--purge` flag sent to the `apt-get remove` command.
* `--recommends`
  * _Only for `apt_install`_: performs the installation with the `--install-recommends` flag sent to the `apt-get install` command.

## Printing into the terminal
Please use the functions exported from `sources/functions/color_echo` that are available whenever something is ran from the context of either `box` or `setup.sh`.

### Formatting prints
* Instead of making a sequence of the same exact echo calls to make new line separation, please use the `\n`, or make your quoted text span multiple lines (with no pre-pending white spaces) instead. THe output will be nicely indented. as a result.
* In general, there should be no un-styled prints thrown at the end-user.

### Logging
* The `echo_...` calls mentioned below will automatically make a copy of the messages.
* Please make sure that your `$log` variable is only used to refer to the path of the log (imported from either `setup.sh` or `box`)
* Any application return/verbose(-ish) print should go into the log file
  * Please make sure your `apt` calls are not `-q/--quiet` when forwarding to the log file, for example

### Available functions and uses
The file mentioned above has a function embedded to show a couple examples of how will the resulting echo look like, please consult these in your own terminal by running the following code below. Smaller test units are available for `echo_test_wrap`, `echo_test_log` and `echo_test_basic`
```bash
. /etc/swizzin/sources/functions/color_echo
echo_tests
```
There is a wide choice of "styles" to choose from, please use them appropriately. Here is a small guide on their use
* Ensure you are correctly outputting to the log
* Make sure the `echo_...` calls are on the "inside of the function", not outside and around it.
  * TODO Clarify what his means
* `echo_success` is meant to be the final echo printed in the event an installation was successful.
* `echo_error` is meant to be the final echo printed in the event something irrecoverable happens, or an abortion is encountered.
* `echo_warn` is meant to alert the user to some of the following examples:
  * Something irrecoverable is about to happen
  * A user-recoverable error has been encountered
  * Basic problems with
* `echo_info` is meant to highlight to user some important information such as the following examples:
  * ports that have been chosen
  * Important generated values that should be recorded
  * necessary follow up steps
  * pointers to documentation, etc
* `echo_query` is meant to highlight the fact user interaction is required
* `echo_progress_start` and `echo_progress_done` are meant to be used to "wrap" a chunk of code that can take a while to complete. If it takes more than 0.1s, you should probably wrap it in this. Examples could be:
  * Doing `apt` calls like `install`, `update`, `upgrade`, etc.
  * Generating ciphers/keys
  * Git pulls/clones
  * Downloads of larger files
  * Recursive `chown`s/`chmod`s on large directories
* `echo_log_only` is meant to store input directly into the logfile, and bypass the end user terminal entirely. Please log anything of note that could help troubleshoot anything when a user has problems, such as the following:
  * Any generated unique values that need to match some specification (e.g. ports)
  * Any variables that are getting assigned from either the user or from the return of a command/function



## Logging
As mentioned above, please ensure any relevant information/print that is generated during the script is corretly forwarded to the destination of the `$log` file.

If necessary, please append the `$log` forward with `2>&1` to redirect all `stderr` to `stdout`, and therefore into the log as well. If you expect these possibilities to happen, please make sure to catch this within your script and error out too, you know.

## Python applications
As a principle, please avoid installing Python2 applications. 

Due to how Python is being versioned, please see the python functions available in `sources/function/python`.

Please use virtual environments only for applications that require a specific or an outdated version of Python.

## Service files
Please include service files for application management. Use the `%i` feature for multi-user applications, avoid for single-instance applications.

## User management
Whenever possible, please describe how is user management done within your application, and how you have adjusted `box` to handle this.

## Documentation
For new applications, please make sure to make the necessary documentation pages on the [Swizzin Docs](https://github.com/liaralabs/docs.swizzin.ltd) repo. It's nice and convenient when you include the link to the Documentation repo PR in the PR here.

## `sysinfo` support
In case you are making any changes to do with applications, please ensure that the `box sysinfo` command still gives correct output, and the application's variables in `scripts/logging/` are still correct. If they don't exist, please take the time to create and test them.