#region Worked
dotnet new unoapp -o HelloEntra -preset "recommended" -markup "csharp" -platforms "wasm" -auth "msal" -renderer "native" `
                  -pwa False -presentation "none" -http "none" -di False -log "none" -nav "blank" -toolkit False -dsp False


cd HelloEntra
cd HelloEntra
dotnet run --framework net9.0-browserwasm
#endregion

#Build wasn't needed.
dotnet build -f net9.0-browserwasm


#region other commands 
winget install --id 'Microsoft.DotNet.SDK.9'
dotnet workload install wasm-tools
dotnet --info  #Needs .net 9

dotnet tool install -g uno.check
dotnet new install Uno.Templates

uno-check --target wasm --fix --force-dotnet --skip vswin --skip vswinworkloads --verbose





#endregion

#region Publish and serve using .net tools.
# 6. Build & publish for WebAssembly
dotnet publish -f net9.0-browserwasm -c Release -o ./publish

# 7. Serve the app locally
dotnet tool install -g dotnet-serve
dotnet-serve -d ./publish/wwwroot -p 8080
#endregion