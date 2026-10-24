$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
foreach ($compilePass in 1..2) {
    xelatex -interaction=nonstopmode -halt-on-error -jobname=作业1 main.tex
    if ($LASTEXITCODE -ne 0) { throw "XeLaTeX failed on pass $compilePass." }
}
Write-Host 'Compiled: 作业1.pdf'
