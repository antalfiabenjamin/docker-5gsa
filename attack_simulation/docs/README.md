# Experimental attack simulation and mitigation

### Rogue gNB registration over IPv6

Example command to run:

docker run -it --rm --name rogue-gnb --network open5gs-lab_5g-ran -v $(pwd)/attack_simulation/registration-attacks/rogue-gnb/rogue-gnb.yaml:/ueransim/config/gnb.yaml:ro 919c50e9bc5d bash

nr-gnb -c /config/gnb.yaml

This will trigger an SCTP association on IPv6, but this can done similarly with IPv4.

Use iptables (or nftables) to block traffic on AMF:

##### IPv4

sudo iptables -A INPUT -i ens33 -p sctp -s 10.200.0.200 --dport 38412 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -i ens33 -p sctp --dport 38412 -j DROP

##### IPv6

sudo ip6tables -A INPUT -i ens33 -p sctp -s fd00:200::200/128 --dport 38412 -m state --state NEW,ESTABLISHED -j ACCEPT
sudo ip6tables -A INPUT -i ens33 -p sctp --dport 38412 -j DROP