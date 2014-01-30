#!/bin/bash

MESSAGE=$(cat)
MESSAGE=$( echo "$MESSAGE" )

LDAPServer='ldap://dc1.contoso.com'
LDAPUser='ldap@CONTOSO.com'
LDAPPassword='P@$$w0rd'

To=$1
To=$( echo $To | sed 's/\n//g' )

IFS=","

function sendToGroup {

  addresses=`ldapsearch -LLL -x -H $LDAPServer -D $LDAPUser -w $LDAPPassword -b ou=People,dc=contoso,dc=com "(mail=$1)" Member | grep member | sed 's/member: //g;s/\n?\r//g' | awk '{print $0";"}'`
  echo $addresses > /home/test.log
  oldIFS=$IFS
  IFS=";"

  for address in $addresses
  do
    account=$( ldapsearch -LLL -x -H $LDAPServer -D $LDAPUser -w $LDAPPassword -b OU=People,DC=contoso,DC=com "(distinguishedName=$address)" sAMAccountName | grep "sAMAccountName:" | awk '{print $2}' )
    echo "$2" | /usr/libexec/dovecot/deliver -d $account    
  done

  IFS=$oldIFS

}

function sendToPerson {

  account=$( ldapsearch -LLL -x -H $LDAPServer -D $LDAPUser -w $LDAPPassword -b ou=People,dc=contoso,dc=com "(|(mail=$1)(otherMailbox=$1))" sAMAccountName | grep "sAMAccountName:" | awk '{print $2}' )
  echo "$2" | /usr/libexec/dovecot/deliver -d $account 
}

for recipient in $To
do
  recipient=$( echo $recipient | sed 's/.*<//g;s/>//g;s/\s//g' )	  
  ADObject=$( ldapsearch -LLL -x -H $LDAPServer -D $LDAPUser -w $LDAPPassword -b ou=People,dc=contoso,dc=com "(|(mail=$recipient)(otherMailbox=$recipient))" objectClass | egrep 'person|group' | awk '{print $2}' )
  case $ADObject in
  "group")
     sendToGroup $recipient "$MESSAGE"
     ;;
  "person")
     sendToPerson $recipient "$MESSAGE"
     ;;
  esac
done
