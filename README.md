# PRTG FlexLM License Usage Sensor Script

This script is designed to be used as a PRTG custom sensor to monitor FlexLM license usage. It parses license usage logs and reports the number of currently checked-out licenses for various products, providing multiple channels for monitoring each product.

## Features

- Retrieves FlexLM license usage data from the specified server.
- Parses log files and extracts detailed information about license usage (checkout and return events).
- Provides multiple channels in PRTG, one for each license type, displaying the number of active licenses.
- Dynamically adjusts the monitored license count based on log activity.

## How to Use

1. **Copy the script**  
   Place the script on the PRTG Server ```C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\EXEXML```

3. **Create a Custom Sensor**  
   - Log into your PRTG interface.
   - Create a new custom sensor on the device that should monitor the license server.
   - Select **"EXE/Script Advanced"** as the sensor type.
   - Point the sensor to the script file and provide the required parameter (`Servername`) in the sensor settings.
     - Parameters =  ```-Servername %device```
     - Security Context = ```Use Windows credentials of parent device```  (make sure to specify the credentials, which have the rights to access the target server via Powershell, try ```Enter-PSSession -ComputerName $myServer -Credentials (Get-Credential)```
     - Scanning interval = ```10 Minutes``` (should be sufficient. The script may run for some seconds depending on the size of the ```C:\Program Files (x86)\SOLIDWORKS Corp\SolidNetWork License Manager\lmgrd.log```

4. **Script Parameters**  
   - `Servername`: The name of the FlexLM license server that the script should connect to.

   
5. **Channels**  
The script dynamically creates a PRTG sensor channel for each unique license found in the log file. For each channel, the number of licenses currently checked out will be reported.

## Example Output of the script for PRTG
```
<prtg>
<result>
  <channel>ProductA</channel>
  <value>5</value>
</result>
<result>
  <channel>ProductB</channel>
  <value>2</value>
</result>
<result>
  <channel>ProductC</channel>
  <value>0</value>
</result>
</prtg>
```
Each <result> tag represents a license type and the corresponding number of checked-out licenses.

6. **Requirements**
  - PowerShell 5.1 or later
  - Access to the FlexLM license manager's log files
  - PRTG with permissions to run PowerShell scripts on the probe

7. **License**
  - This script is provided as-is, with no warranty or support. Feel free to modify it to suit your environment.
