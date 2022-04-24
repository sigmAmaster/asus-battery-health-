#!/bin/bash

dialog --title "Welcome to Asus Battery Health"\
         --msgbox "         
         This App Can Control Your Battery Charging 
         You Can Set Value For Stop Over Charge Your Battery
         For Shutdown Just Enter off 
         
         NOTE : Run App With sudo Command
         Develop By sigmAmster" 12 60 



function rewrite(){
    if [ $1 == "off" ];
    then

          $(echo "100" > $2)
          
          systemctl daemon-reload
          systemctl enable battery-charge-threshold.service
          systemctl restart battery-charge-threshold.service

          $(sudo rm $3 $2)

          systemctl disable battery-charge-threshold.service
          systemctl stop battery-charge-threshold.service
        
          dialog --msgbox  "OFF" 10 10
          exit 0

      else
          $(echo $1 > $2)
          
          systemctl daemon-reload
          systemctl enable battery-charge-threshold.service
          systemctl restart battery-charge-threshold.service
        
          dialog --msgbox "Done set on $1" 10 20
          exit 0
      fi

}

function set_value(){

  file=$(ls /etc/systemd/system/battery-charge-threshold.service)
  batt_name=$(ls -d /sys/class/power_supply/B* | awk -F'/' '{print $5 }')
  
  default="/etc/systemd/system/battery-charge-threshold.service"

  data="/usr/asus_battery_health"
   
   stop_command="
      \n
      [Unit]\n
      Description=Set the battery charge threshold\n
      After=multi-user.target\n
      \n
      [Service]\n
      Type=simple\n
      Restart=always\n
      RestartSec=1\n
      ExecStart=/bin/bash -c 'cp $data /sys/class/power_supply/$batt_name/charge_control_end_threshold'\n
      \n
      [Install]\n
      WantedBy=multi-user.target\n"
  

  if [ -n "$batt_name" ];
  then 
    

      if [ $file == $default ]; #check file doesnt exist if exist just edit
      then
          rewrite $1 $data $default


      else         
          $(echo $1 >> $data)
          $(echo -e $stop_command >> $default )
          
          sudo systemctl enable battery-charge-threshold.service
          sudo systemctl start battery-charge-threshold.service
        
          dialog --msgbox "Done set on $1" 10 20
          exit 0
      fi
  
  else
    dialog --msgbox "ERROR !!!
    Can't Find Battery Information !?" 10 60
  fi


}

function UI(){
min=1
max=100

input=$(\
  dialog --title "Asus Battery Health" \
  --inputbox "threshold: " 40 40 \
  3>&1 1>&2 2>&3 3>&- \
)

if [ $input == "off" ];
 then
  set_value "off"
  exit 0

elif  [ "${input}" -ge "${min}"   ] && [ "${input}" -le "${max}"   ] ;
  then
      set_value $input

else
  dialog --msgbox "error invalid argument !!!
  try again" 10 30
  exit 0
fi
}

check=$(ls /sys/class/power_supply/BAT*/charge_control_end_threshold)
default="/sys/class/power_supply/BAT*/charge_control_end_threshold"

if [ $check == $default ];
 then
    UI
else
  dialog --msgbox "Your Computer Doesn't Support Charge Control :(" 10 60
fi
