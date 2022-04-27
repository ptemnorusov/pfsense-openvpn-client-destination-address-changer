#!/usr/local/bin/bash
#pfsense vpn destination address changer


#Stage 1
#get old vpn destination server ip address
old_server=$( grep 1194 /var/etc/openvpn/client6/config.ovpn | awk '{print $2}' )

#make new vpn destination server ip address
random_line=$(echo $(( $RANDOM % 2020 + 1 ))"p")
new_server=$(sed -n $random_line /root/pfsense-openvpn-client/vpn-servers.txt )
#echo $old_server, $new_server

#find and change address in the config file
sed -i.bak "s/$old_server/$new_server/g" /var/etc/openvpn/client6/config.ovpn
grep 1194 /var/etc/openvpn/client6/config.ovpn | awk '{print $2}'


#Stage 2
#get old vpn destination server ip address
old_server=$(grep --line-buffered "<vpnid>6"  /cf/conf/config.xml -A 6 | grep server_addr | awk -F '[<>]' '/server_addr/{print $3}')

#find and change address in the config file
sed -i.bak "s/$old_server/$new_server/g" /cf/conf/config.xml
grep --line-buffered "<vpnid>6"  /cf/conf/config.xml -A 6 | grep server_addr | awk -F '[<>]' '/server_addr/{print $3}'

#restart openvpn-client service
/usr/local/sbin/pfSsh.php playback svc stop openvpn client 6
sleep 5
/usr/local/sbin/pfSsh.php playback svc start openvpn client 6
#/usr/local/sbin/pfSsh.php playback svc restart openvpn client 6
sleep 3

#get vpn client interfaces' ip addresse
vpn9=$(ifconfig | grep ovpnc9 -A 1 | grep 'inet ' | awk '{print $2}')
vpn6=$(ifconfig | grep ovpnc6 -A 1 | grep 'inet ' | awk '{print $2}')

#compare addresses. They must not be equal. Otherwise reconnect
if [ "$vpn9" == "$vpn6" ]
then
	#if equal, restart and reconnect
	echo "VPNs have identical Ips $vpn6 $vpn9"
	/usr/local/sbin/pfSsh.php playback svc stop openvpn client 6 
	sleep 5 
	/usr/local/sbin/pfSsh.php playback svc start openvpn client 6 
	
	#and check again
	if [ $vpn9 = $vpn6 ]; 
	then 
		/usr/local/sbin/pfSsh.php playback svc stop openvpn client 6 
		sleep 5 
		/usr/local/sbin/pfSsh.php playback svc start openvpn client 6 
	fi
fi
