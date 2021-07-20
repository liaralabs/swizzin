#!/bin/bash
# Package installer for The Lounge IRC Web Client
# Author: Liara

function _install() {

    useradd lounge --system -m -d /opt/lounge

    npm -g config set user root || {
        echo_error "npm config step failed"
        exit 1
    }

    echo_progress_start "Installing lounge from npm"
    npm install -g thelounge >> $log 2>&1 || {
        echo_error "Lounge failed to install"
        exit 1
    }
    sudo -u lounge bash -c "thelounge install thelounge-theme-zenburn" >> $log 2>&1
    echo_progress_done

    mkdir -p /opt/lounge/.thelounge/

    cat > /opt/lounge/.thelounge/config.js << 'EOF'
"use strict";

module.exports = {
	//
	// Set the server mode.
	// Public servers does not require authentication.
	//
	// Set to 'false' to enable users.
	//
	// @type     boolean
	// @default  true
	//
	public: false,

	//
	// IP address or hostname for the web server to listen on.
	// Setting this to undefined will listen on all interfaces.
	//
	// @type     string
	// @default  undefined
	//
	host: undefined,

	//
	// Set the port to listen on.
	//
	// @type     int
	// @default  9000
	//
	port: 9000,

	//
	// Set the local IP to bind to for outgoing connections. Leave to undefined
	// to let the operating system pick its preferred one.
	//
	// @type     string
	// @default  undefined
	//
	bind: undefined,

	//
	// Sets whether the server is behind a reverse proxy and should honor the
	// X-Forwarded-For header or not.
	//
	// @type     boolean
	// @default  false
	//
	reverseProxy: false,

	//
	// Set the default theme.
	// Find out how to add new themes at https://thelounge.github.io/docs/packages/themes
	//
	// @type     string
	// @default  "example"
	//
	theme: "thelounge-theme-zenburn",

	//
	// Prefetch URLs
	//
	// If enabled, The Lounge will try to load thumbnails and site descriptions from
	// URLs posted in channels.
	//
	// @type     boolean
	// @default  false
	//
	prefetch: true,

	//
	// Store and proxy prefetched images and thumbnails.
	// This improves security and privacy by not exposing client IP address,
	// and always loading images from The Lounge instance and making all assets secure,
	// which in result fixes mixed content warnings.
	//
	// If storage is enabled, The Lounge will fetch and store images and thumbnails
	// in ~/.lounge/storage folder, or %HOME%/storage if --home is used.
	//
	// Images are deleted when they are no longer referenced by any message (controlled by maxHistory),
	// and the folder is cleaned up on every The Lounge restart.
	//
	// @type     boolean
	// @default  false
	//
	prefetchStorage: false,

	//
	// Prefetch URLs Image Preview size limit
	//
	// If prefetch is enabled, The Lounge will only display content under the maximum size.
	// Specified value is in kilobytes. Default value is 512 kilobytes.
	//
	// @type     int
	// @default  512
	//
	prefetchMaxImageSize: 2048,

	//
	// Display network
	//
	// If set to false network settings will not be shown in the login form.
	//
	// @type     boolean
	// @default  true
	//
	displayNetwork: true,

	//
	// Lock network
	//
	// If set to true, users will not be able to modify host, port and tls
	// settings and will be limited to the configured network.
	//
	// @type     boolean
	// @default  false
	//
	lockNetwork: false,

	//
	// Hex IP
	//
	// If enabled, clients' username will be set to their IP encoded has hex.
	// This is done to share the real user IP address with the server for host masking purposes.
	//
	// @type     boolean
	// @default  false
	//
	useHexIp: false,

	//
	// WEBIRC support
	//
	// If enabled, The Lounge will pass the connecting user's host and IP to the
	// IRC server. Note that this requires to obtain a password from the IRC network
	// The Lounge will be connecting to and generally involves a lot of trust from the
	// network you are connecting to.
	//
	// Format (standard): {"irc.example.net": "hunter1", "irc.example.org": "passw0rd"}
	// Format (function):
	//   {"irc.example.net": function(client, args, trusted) {
	//       // here, we return a webirc object fed directly to `irc-framework`
	//       return {username: "thelounge", password: "hunter1", address: args.ip, hostname: "webirc/"+args.hostname};
	//   }}
	//
	// @type     string | function(client, args):object(webirc)
	// @default  null
	webirc: null,

	//
	// Maximum number of history lines per channel
	//
	// Defines the maximum number of history lines that will be kept in
	// memory per channel/query, in order to reduce the memory usage of
	// the server. Setting this to -1 will keep unlimited amount.
	//
	// @type     integer
	// @default  10000
	maxHistory: 10000,

	//
	// Set socket.io transports
	//
	// @type     array
	// @default  ["polling", "websocket"]
	//
	transports: ["polling", "websocket"],

	//
	// Run The Lounge using encrypted HTTP/2.
	// This will fallback to regular HTTPS if HTTP/2 is not supported.
	//
	// @type     object
	// @default  {}
	//
	https: {
		//
		// Enable HTTP/2 / HTTPS support.
		//
		// @type     boolean
		// @default  false
		//
		enable: false,

		//
		// Path to the key.
		//
		// @type     string
		// @example  "sslcert/key.pem"
		// @default  ""
		//
		key: "",

		//
		// Path to the certificate.
		//
		// @type     string
		// @example  "sslcert/key-cert.pem"
		// @default  ""
		//
		certificate: "",

		//
		// Path to the CA bundle.
		//
		// @type     string
		// @example  "sslcert/bundle.pem"
		// @default  ""
		//
		ca: ""
	},

	//
	// Run The Lounge with identd support.
	//
	// @type     object
	// @default  {}
	//
	identd: {
		//
		// Run the identd daemon on server start.
		//
		// @type     boolean
		// @default  false
		//
		enable: false,

		//
		// Port to listen for ident requests.
		//
		// @type     int
		// @default  113
		//
		port: 113
	},

	//
	// Enable oidentd support using the specified file
	//
	// Example: oidentd: "~/.oidentd.conf",
	//
	// @type     string
	// @default  null
	//
	oidentd: null,

	//
	// LDAP authentication settings (only available if public=false)
	// @type    object
	// @default {}
	//
	ldap: {
		//
		// Enable LDAP user authentication
		//
		// @type     boolean
		// @default  false
		//
		enable: false,

		//
		// LDAP server URL
		//
		// @type     string
		//
		url: "ldaps://example.com",

		//
		// LDAP base dn
		//
		// @type     string
		//
		baseDN: "ou=accounts,dc=example,dc=com",

		//
		// LDAP primary key
		//
		// @type     string
		// @default  "uid"
		//
		primaryKey: "uid"
	},

	// Extra debugging
	//
	// @type     object
	// @default  {}
	//
	debug: {
		// Enables extra debugging output provided by irc-framework.
		//
		// @type     boolean
		// @default  false
		//
		ircFramework: false,

		// Enables logging raw IRC messages into each server window.
		//
		// @type     boolean
		// @default  false
		//
		raw: false,
	},
};
EOF

    chown -R lounge: /opt/lounge

    if [[ -f /install/.nginx.lock ]]; then
        echo_progress_start "Configuring nginx"
        bash /usr/local/bin/swizzin/nginx/lounge.sh
        systemctl reload nginx
        echo_progress_done
    else
        echo_info "Lounge will run on port 9000"
    fi

    echo_progress_start "Installing systemd service"
    cat > /etc/systemd/system/lounge.service << EOSD
[Unit]
Description=The Lounge IRC client
After=znc.service

[Service]
Type=simple
ExecStart=/usr/bin/thelounge start
User=lounge
Group=lounge
Restart=on-failure
RestartSec=5
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOSD

    systemctl enable -q --now lounge 2>&1 | tee -a $log

    sleep 3
    echo_progress_done "Lounge started"
}

function _adduser() {
    master=$(cut -d: -f1 < /root/.master.info)
    for u in "${users[@]}"; do
        echo_progress_start "Adding $u to lounge"
        if [[ $u = "$master" ]]; then
            password=$(cut -d: -f2 < /root/.master.info)
        else
            password=$(cut -d: -f2 < /root/$u.info)
        fi
        crypt=$(node /usr/lib/node_modules/thelounge/node_modules/bcryptjs/bin/bcrypt "${password}")
        cat > /opt/lounge/.thelounge/users/$u.json << EOU
{
	"password": "${crypt}",
	"log": true,
	"awayMessage": "",
	"networks": [],
	"sessions": {}
}
EOU
        echo_progress_done "Added $u to lounge"
    done
    chown -R lounge: /opt/lounge
}

users=($(cut -d: -f1 < /etc/htpasswd))

if [[ -n $1 ]]; then
    users=$1
    _adduser
    exit 0
fi

#shellcheck source=sources/functions/npm
. /etc/swizzin/sources/functions/npm
npm_install || exit 1
_install
_adduser

echo_success "Lounge installed"
touch /install/.lounge.lock
