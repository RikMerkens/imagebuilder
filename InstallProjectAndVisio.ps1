# Install with ODT Project and Visio
$ProgressPreference = 'SilentlyContinue'

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/RikMerkens/imagebuilder/master/odt/Configuration.xml" -OutFile "C:\Temp\Install\Configuration.XML"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/RikMerkens/imagebuilder/master/odt/setupODT.exe" -OutFile "C:\Temp\Install\setupODT.exe"

C:\temp\Install\setupODT.exe /configure C:\temp\Install\configuration.xml