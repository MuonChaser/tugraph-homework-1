$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$imageName = 'tugraph-assignment-clean:4.5.1'
$containerName = 'tugraph-assignment'
$packageFile = Join-Path $PSScriptRoot 'vendor/tugraph-4.5.1-1.el7.x86_64.rpm'
$expectedHash = 'D9AFCD3194C4D1A6B1E0C0309636711A6E69B4E48D8B5C23986CEEF2C83D9C88'
New-Item -ItemType Directory -Force vendor,runtime,runtime/db | Out-Null
if (-not (Test-Path -LiteralPath $packageFile)) {
    Invoke-WebRequest -Uri 'https://github.com/TuGraph-family/tugraph-db/releases/download/v4.5.1/tugraph-4.5.1-1.el7.x86_64.rpm' -OutFile $packageFile
}
if ((Get-FileHash -LiteralPath $packageFile -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Downloaded package hash differs from the recorded version. Check the official release before continuing.'
}
docker build --pull=false -t $imageName .
if ($LASTEXITCODE -ne 0) { throw 'Docker image build failed.' }
$existingJson = docker container inspect $containerName 2>$null
if ($LASTEXITCODE -eq 0) {
    $existing = ($existingJson | ConvertFrom-Json)[0]
    $existingMount = $existing.Mounts | Where-Object Destination -EQ '/workspace'
    if ($existing.Config.Image -ne $imageName -or $existingMount.Source -ne $PSScriptRoot) {
        throw 'A different container uses this name. Choose another container name before continuing.'
    }
    docker start $containerName
} else {
    if (-not (Get-ChildItem -LiteralPath 'runtime/db' -Force | Select-Object -First 1)) {
        docker run --rm --mount "type=bind,source=$PSScriptRoot,target=/workspace" --entrypoint /usr/local/bin/lgraph_import $imageName --config_file /workspace/data/import.json --dir /workspace/runtime/db --graph medical_demo 2>&1 | Tee-Object -FilePath runtime/import.log
        if ($LASTEXITCODE -ne 0) { throw 'Data import failed.' }
    }
    docker run -d --name $containerName --restart unless-stopped -p 127.0.0.1:17070:7070 -p 127.0.0.1:17687:7687 -p 127.0.0.1:19090:9090 --mount "type=bind,source=$PSScriptRoot,target=/workspace" $imageName
}
if ($LASTEXITCODE -ne 0) { throw 'Container startup failed.' }
Write-Host 'Browser: http://127.0.0.1:17070'
Write-Host 'Bolt: bolt://127.0.0.1:17687'
Write-Host 'Initial demo login: admin / 73@TuGraph'
docker ps --filter "name=$containerName"
