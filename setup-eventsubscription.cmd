az account list -o table
echo "start ps1"
powershell.exe -File "./setup-eventsubscription.ps1"
echo "end ps1"
