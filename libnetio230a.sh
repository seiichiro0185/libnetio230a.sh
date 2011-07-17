####################################################################
#                                                                  #
# libnetio230a.sh - Library for controlling the netio 230A         #
# LAN IP Remote socket using the CGI interface                     #
#                                                                  #
# (C) Stefan Brand <seiichiro@seiichiro0185.org> 2011              #
#                                                                  #
# Released under the terms of the GPL v3 or later                  #
# (see COPYING for details)                                        #
#                                                                  #
####################################################################


# send: send arbitary command string
# Parameters: IP-Address/DNS-Name, CGI-Commandstring

function netio.send()
{
	_ip="$1"
	_command="$2"
	wget --quiet --load-cookies /tmp/netio$$.cookie --save-cookies /tmp/netio$$.cookie "http://${_ip}/tgi/control.tgi?${_command}" -O - 2>/dev/null | sed -e 's#<html>\W*##;s#\W*</html>##'
}


# login: establish authenticated session, is remembered for the current shell/script
# Parameters: IP-Address/DNS-Name, Login Method [p(lain)/c(crypted)], Username, Password
# Return: 0 for successfull login, 2 for error

function netio.login()
{
	_ip="$1"
	_method=$2
	_user=$3
	_pw=$4

	if [ "${_method}" == "p" ]
	then
		_ret=$(netio.send ${_ip} "l=p:${_user}:${_pw}" | awk '{print $1}')
	fi
	if [ "$_{method}" == "c" ]
	then
		_hash=$(netio.send ${_ip} "h=h")
		_crypt=$(echo -n "${_user}${_pw}${_hash}" | md5sum | awk '{print $1}')
		_ret=$(netio.send ${_ip} "l=c:${_user}:${_crypt}" | awk '{print $1}')
	fi

	if [ ${_ret} -eq 100 ] || [ ${_ret} -eq 554 ]
	then
		return 0
	else
		return 2
	fi
}

# logout: terminate session
# Parameters: IP-Address/DNS-Name

function netio.logout()
{
	_ip=$1
	netio.send ${_ip} "q=q" >/dev/null
	rm /tmp/netio$$.cookie
}

# getport: Get port status of given port
# Parameters: IP-Address/DNS-Name, Port to check
# Return: 0 or 1 for port status, 2 if not authenticated

function netio.getport()
{
	_ip=$1
	_port=$2
	_ret=$(netio.send ${_ip} "p=l")
	
	if [ $(echo "${_ret}" |awk '{print $1}') -eq 555 ]
	then
		return 2
	else
		return $(echo "${_ret}" |awk "{print \$${_port}}")
	fi
}

# setport: Change port status of given port
# Parameters: IP-Address/DNS-Name, port to change, state to set [0(off)/1(on)/i(interrupt)]
# Return: 0 if port status was changed, 2 for error
function netio.setport()
{
	_ip=$1
	_port=$2
	_state=$3

	case $_port in
		1) _ret=$(netio.send ${_ip} "p=${_state}uuu" | awk '{print $1}');;
		2) _ret=$(netio.send ${_ip} "p=u${_state}uu" | awk '{print $1}');;
		3) _ret=$(netio.send ${_ip} "p=uu${_state}u" | awk '{print $1}');;
		4) _ret=$(netio.send ${_ip} "p=uuu${_state}" | awk '{print $1}');;
		*) _ret=555;;
	esac

	if [ $_ret -eq 250 ]
	then
		return 0
	else
		return 2
	fi
}
