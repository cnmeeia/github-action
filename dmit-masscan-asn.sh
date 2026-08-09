#!/bin/bash

set -e


RATE=100000

WORKDIR="dmit-result"

ASN_ALLOW="32519"

mkdir -p $WORKDIR


# ==========================
# DMIT Tokyo IP ranges
# ==========================

cat > ranges.txt <<EOF
154.12.190.0/23
154.31.112.0/24
154.31.118.0/24
103.117.102.0/23
103.117.103.0/24
EOF



echo "[+] Masscan start"


sudo masscan \
-iL ranges.txt \
-p1-65535 \
--rate $RATE \
--wait 10 \
-oG $WORKDIR/open.gnmap



echo "[+] Extract IP PORT"


grep "Ports:" \
$WORKDIR/open.gnmap \
| awk '
{
ip=$2
match($0,/([0-9]+)\/open/,p)
if(p[1])
print ip":"p[1]
}' \
> $WORKDIR/open.txt



echo "[+] ASN checking"


> $WORKDIR/asn-ok.txt


while read item
do


IP=$(echo $item | cut -d: -f1)
PORT=$(echo $item | cut -d: -f2)


ASN=$(whois $IP 2>/dev/null \
| grep -Ei "origin|originas|aut-num" \
| grep -oE "AS[0-9]+" \
| head -1)



ORG=$(whois $IP 2>/dev/null \
| grep -Ei "OrgName|org-name|owner" \
| head -1)



if [[ "$ASN" == "AS$ASN_ALLOW" ]]
then

echo "$IP:$PORT $ASN $ORG" \
>> $WORKDIR/asn-ok.txt

fi


done < $WORKDIR/open.txt



echo
echo "[+] DMIT ASN Result"

cat $WORKDIR/asn-ok.txt



echo
echo "[+] Ping ranking"



> $WORKDIR/final.txt


while read line
do


TARGET=$(echo $line | awk '{print $1}')

IP=$(echo $TARGET | cut -d: -f1)



PING=$(ping -c 3 -W 1 $IP 2>/dev/null \
| tail -1 \
| awk -F "/" '{print $5}')



if [ ! -z "$PING" ]
then

echo "$PING ms $line" \
>> $WORKDIR/final.txt

fi


done < $WORKDIR/asn-ok.txt



sort -n $WORKDIR/final.txt \
-o $WORKDIR/final.txt



echo
echo "===================="
echo " DMIT Tokyo TOP"
echo "===================="


head -50 $WORKDIR/final.txt