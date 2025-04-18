

### WIN GET

```bash
#no terminal do windonws: executar como adm o terminal
winget list #lista todos os pacotes instalados no win
winget upgrade
winget export -o C:\Users\klysm\Documents\GitHub\Klysman\Windows\wingetlist.json #export all available packeges in winget.
winget import -i C:\Users\klysm\Documents\GitHub\Klysman\Windows\wingetlist.json #install all packeges 
winget upgrade --all

```

```bash
Step 1: Type cmd in the Search box and choose the first result. Then, click Run as administrator.

Step 2: Once Command Prompt’s window opens you can put the following command and press Enter:

reg add “HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32” /f /ve

Step 3: Restart your computer.
```
