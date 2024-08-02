# Determine the architecture of the macOS device 
processorBrand=$(/usr/sbin/sysctl -n machdep.cpu.brand_string) 
if [[ "${processorBrand}" = *"Apple"* ]]; then 
    echo "Apple Processor is present." 
else 
    echo "Apple Processor is not present. Rosetta not required." 
    exit 0 
fi 
 
# Check if Rosetta is installed 
checkRosettaStatus=$(/bin/launchctl list | /usr/bin/grep "com.apple.oahd-root-helper") 
RosettaFolder="/Library/Apple/usr/share/rosetta" 
if [[ -e "${RosettaFolder}" && "${checkRosettaStatus}" != "" ]]; then 
    echo "Rosetta Folder exists and Rosetta Service is running. Exiting..." 
    exit 0 
else 
    echo "Rosetta Folder does not exist or Rosetta service is not running. Installing Rosetta..." 
fi 
 
# Install Rosetta 
/usr/sbin/softwareupdate --install-rosetta --agree-to-license 
 
# Check the result of Rosetta install command 
if [[ $? -eq 0 ]]; then 
    echo "Rosetta installed successfully." 
    exit 0 
else 
    echo "Rosetta installation failed." 
    exit 1 

fi 
exit 0 