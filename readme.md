# Action for ideckia: FtpConnect

## Definition

Create connections via ftp (it is using Filezilla by default)

### Custom name in connection window (filezilla exclusive)

* Open filezilla
  * Session
    * 'Saved Sessions' -> 'Default Settings' -> Load
  * Terminal
    * Features
      * Check 'Disable remote-controlled window title changing'
  * Session
    * 'Saved Sessions' -> 'Default Settings' -> Save
      

## Properties

| Name | Type | Default | Description | Possible values |
| ----- |----- | ----- | ----- | ----- |
| executable_path | String | null | Custom FTP executable path. If omitted, will look for 'filezilla' in PATH environment variable. | null |
| is_secure | Bool | null | Will it use secure connection (sftp)? | null |
| ftp_server | String | null | The FTP server (with port) | null |
| ftp_user | String | null | Throgh ftp user | null |
| ftp_password | String | null | Throgh ftp password | null |
| color | { disconnected : String, connected : String } | { connected : 'ff00aa00', disconnected : 'ffaa0000' } | Color definitions | null |


## Example in layout file

```json
{
    "state": {
        "text": "FTP connection example",
        "bgColor": "00ff00",
        "actions": [{
            "name": "ftp-connect",
            "props": {
                "executable_path": "/alt/path/to/ftp",
                "is_secure": true,
                "ftp_server": "my.ftp.host",
                "ftp_user": "user",
                "ftp_password": "securePass"
            }
        }]
    }
}
```