!Cloud-init script for ASAv
hostname ${hostname}
enable password Cisco@123
!
ip local pool ${hostname}-VPN-POOL ${vpn_pool_min}-${vpn_pool_max} mask ${vpn_mask}
!
interface management 0/0
 no ip address dhcp setroute
 ip address ${management_ip}
 management-only
 nameif management
!
interface GigabitEthernet 0/0
 nameif outside
 ip address ${outside_ip}
!
interface GigabitEthernet 0/1
 nameif inside
 ip address ${inside_ip}
!
same-security-traffic permit inter-interface
same-security-traffic permit intra-interface 
!
dns domain-lookup outside
dns server-group DefaultDNS
 name-server 169.254.169.254
!
object network ${hostname}-VPN-POOL
 subnet ${vpn_pool_subnet} ${vpn_mask}
!
access-list Split-Tunnel standard permit 10.0.0.0 255.0.0.0
!
nat (inside,outside) source static any any destination static ${hostname}-VPN-POOL ${hostname}-VPN-POOL no-proxy-arp route-lookup
!
route outside 0.0.0.0 0.0.0.0 ${outside_subnet}
route management 0.0.0.0 0.0.0.0 ${management_subnet}
route inside 0.0.0.0 0.0.0.0 ${inside_subnet} tunneled
!
aaa-server ISEv-OCI protocol radius
 dynamic-authorization
aaa-server ISEv-OCI (outside) host ${ise_ip}
 key cisco
 authentication-port 1812
 accounting-port 1813
!
user-identity default-domain LOCAL
aaa authentication ssh console LOCAL 
aaa authentication login-history
!
http server enable
http 0.0.0.0 0.0.0.0 management
!
telnet timeout 5
crypto key generate rsa modulus 2048
ssh stricthostkeycheck
ssh timeout 60
ssh version 2
ssh key-exchange group dh-group14-sha1
!ssh key-exchange group dh-group14-sha256
ssh 0.0.0.0 0.0.0.0 management
!
username admin nopassword privilege 15
username admin attributes
service-type admin
aaa authentication ssh console LOCAL
!
ssl trust-point ASDM_TrustPoint0 outside
ssl trust-point ASDM_TrustPoint0 inside
!
webvpn
 enable outside
 http-headers
  hsts-server
   enable
   max-age 31536000
   include-sub-domains
   no preload
  hsts-client
   enable
  x-content-type-options
  x-xss-protection
  content-security-policy
!anyconnect image disk0:/anyconnect-win-4.10.01075-webdeploy-k9.pkg 1
 anyconnect enable
 tunnel-group-list enable
 cache        
  disable
 error-recovery disable
!
group-policy GroupPolicy_${hostname} internal
group-policy GroupPolicy_${hostname} attributes
 wins-server none
 dns-server value 169.254.169.254 8.8.8.8
 vpn-tunnel-protocol ssl-client 
 split-tunnel-policy tunnelall
 split-tunnel-network-list value Split-Tunnel
 default-domain none
 webvpn
  anyconnect ssl dtls none
  anyconnect profiles value oci-vpn type user
dynamic-access-policy-record DfltAccessPolicy
!
username rantony password Cisco@123
!
username cisco password Cisco@123 privilege 15
!
tunnel-group ${hostname} type remote-access
tunnel-group ${hostname} general-attributes
 address-pool ${hostname}-VPN-POOL
 authentication-server-group LOCAL
 default-group-policy GroupPolicy_${hostname}
tunnel-group ${hostname} webvpn-attributes
 group-alias ${hostname} enable
 group-url https://${vpn_url} enable
!
!license smart
!feature tier standard
!throughput level 20G
!exit
!
!license smart register idtoken ZjliMDg3MzAtMzllOC00Y2MzLWFiZGItMWU1Y2UzYjBlN2JjLTE2MjQxMzYw%0AMTAwMTB8VFdROHlRaHo0amVPRDZUL0JLeDNhQ2Qzdms1akpOU1d3VENua0xE%0AdVk5Yz0%3D%0A
!
! copy /noconfirm ${preauthenticated_bucket_request} disk0:/anyconnect-win-4.10.01075-webdeploy-k9.pkg
!
! webvpn
! anyconnect image disk0:/anyconnect-win-4.10.01075-webdeploy-k9.pkg
!
