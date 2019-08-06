### create function project
$funcproj = "image-processor"
mkdir $funcproj
cd $funcproj
func init --worker-runtime "dotnet" --language "c#"
func new --template "Event Grid trigger" --name "thumbnail"  

dotnet add ".\$funcproj.csproj" package "Microsoft.Azure.EventGrid"
dotnet add ".\$funcproj.csproj" package "Microsoft.Azure.WebJobs.Extensions.EventGrid"
dotnet add ".\$funcproj.csproj" package "Microsoft.Azure.WebJobs.Extensions.Storage" 
dotnet add ".\$funcproj.csproj" package "SixLabors.ImageSharp" -v "1.0.0-beta0005"
dotnet restore
cd ..

