#! /bin/bash
# Duck DNS installer
# Flying_sausages 2020 swizzin gplv3
# shellcheck disable=SC2154

##########################################################
# Gathering variables and gettin go-ahead
##########################################################
if [[ -z $duck_subdomain ]] || [[ -z $duck_token ]]; then
    echo_info "This script requires an account at duckdns.org. You can always refer to the swizzin documentation for guidance.\n https://swizzin.ltd/applications/duckdns"
    echo_query "Would you like to continue?" "y/N"
    read -r yn
    case $yn in
        [Yy]*) : ;;
        *) exit 0 ;;
    esac
fi

if [[ -z $duck_subdomain ]]; then
    echo_query "Enter your full Duck DNS domain" "e.g mydomain.duckdns.org"
    read -r fulldomain
    subdomain="${fulldomain%%.*}"
    domain="${fulldomain#*.}"
    if [ "$domain" != "duckdns.org" ] && [ "$domain" != "$subdomain" ] || [ "$subdomain" = "" ]; then
        echo_error "Invalid domain name. Program will now quit."
        exit 0
    fi
else
    subdomain=$duck_subdomain
    echo_info "Domain set to $subdomain.duckdns.org"
fi

if [[ -z $duck_token ]]; then
    echo_query "Enter your Duck DNS Token value"
    read -r token
    token=$(echo "$token" | tr -d '\040\011\012\015')
else
    token=$duck_token
fi

##########################################################
# Doing stuff
##########################################################

## Making script file and directories

duckPath="/opt/duckdns"
duckLog="$duckPath/duck.log"
duckScript="$duckPath/duck.sh"

if [[ ! -d $duckPath ]]; then
    mkdir -p $duckPath
fi

echo_progress_start "Installing duckdns update script"
cat > $duckScript << EOS
subdomain=$subdomain
token=$token

echo url="https://www.duckdns.org/update?domains=\$subdomain&token=\$token&ip=" | curl -k -o $duckLog -K -
EOS

chmod 700 $duckScript

## Installing into cron
# TODO move cron job aditions tot their own files
checkCron=$(crontab -l | grep -c $duckScript)
if [ "$checkCron" -eq 0 ]; then
    crontab -l | {
        cat
        echo "*/5 * * * * bash $duckScript"
    } | crontab - >> $log 2>&1
fi
echo_progress_done

## Running script
echo_progress_start "Registering domain with Duck DNS"
bash $duckScript >> "$log" 2>&1
response=$(cat $duckLog)
if [ "$response" != "OK" ]; then
    echo_error "Duck DNS did not update correctly. Please check your settings or run the setup again."
    exit 1
fi
echo_progress_done

if [[ -f /install/.nextcloud.lock ]]; then
    echo_progress_start "Adding $domain to Nextcloud"
    #shellcheck source=sources/functions/nextcloud
    . /etc/swizzin/sources/functions/nextcloud
    _occ_add_trusted_domain "$domain"
    echo_progress_done "Domain added to Nextcloud"
fi

echo_success "Duck DNS setup succesfully completed!"
if [[ ! -f /install/.nginx.lock ]]; then
    echo_info "Install LetsEncrypt using the domain \"$subdomain.duckdns.org\" to get SSL encryption\nConsult https://swizzin.ltd/docs/guides/troubleshooting for help with port forwarding."
fi
touch /install/.duckdns.lock
