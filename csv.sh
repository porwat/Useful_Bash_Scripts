#!/bin/bash
# USE IFS for splitting (and elements can have spaces in them)
# source csv format:
# Location;OrganizationUnit;InventoryNumber;Owner;Name;SerialNumber;InstallDate;Price;InvoiceNumber;WarrantyExpDate;Vendor;IncidentState;DeploymentState

IFS=";"
csvfile=$1 #csv file name to import
template=$2 #OTRS import template name

while read -r line
do
  line=$( echo "$line;" )
  newline=""
  i=0
  for x in $line
  do
    pos=$( echo "\"$x\";" )
      if [ $i -eq 3 ]
      then
        #look for a first name and second name and create sAMAccount name without polish chars
        pos=$( echo $x | awk '{print substr($2,0,1)"." $1}' | tr '[:upper:]' '[:lower:]' | sed -e 'y/ąęśćźżńśół/aesczznsol/')
        pos=$( echo "\"$pos\";" )
      fi
      if [ -z "$newline" ]
      then
      newline=$( echo "$pos" )
      else
      newline=$( echo "$newline$pos" )
      fi
    i=$(($i+1))
  done
  newline=$( echo "$newline\"Operational\";\"Production\"" )
  echo "$newline"
  echo "$newline" >> ./OTRSImport.csv
done <$csvfile

#use Import\Export OTRS script to import created csv file
/opt/otrs/bin/otrs.ImportExport.pl -n $template -a import -i ./OTRSImport.csv
rm -f ./OTRSImport.csv
