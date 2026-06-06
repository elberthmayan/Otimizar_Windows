<#
.SYNOPSIS
    win-debloater - Ferramenta de Otimizacao Windows (Menu Interativo).
#>

# Forca o console a usar UTF-8 e evita erros de interpretacao
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# 1. VERIFICACAO DE PRIVILEGIOS
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "ERRO: Este script deve ser executado como Administrador."
    Pause
    exit
}

function Show-Menu {
    Clear-Host
    Write-Host "  __________________________________________________________  " -ForegroundColor Cyan
    Write-Host " |                                                          | " -ForegroundColor Cyan
    Write-Host " |                WIN-DEBLOATER v1.3                        | " -ForegroundColor Cyan
    Write-Host " |        Otimizacao e Padronizacao Corporativa             | " -ForegroundColor Cyan
    Write-Host " |__________________________________________________________| " -ForegroundColor Cyan
    Write-Host " |                                                          | " -ForegroundColor Cyan
    Write-Host " |  [1] Limpar aplicativos inúteis (Spotify, Skype, etc)   | " -ForegroundColor White
    Write-Host " |  [2] Remover o Xbox e funções de Jogos                  | " -ForegroundColor White
    Write-Host " |  [3] Excluir OneDrive (Limpeza completa)                 | " -ForegroundColor White
    Write-Host " |  [4] Desativar Cortana e Copilot (IA)                    | " -ForegroundColor White
    Write-Host " |  [5] Bloquear avisos de Win11 e Conta Local              | " -ForegroundColor White
    Write-Host " |  [6] Ativar o Windows e  Office                          | " -ForegroundColor Magenta
    Write-Host " |  [7] Instalar  o  Office              | " -ForegroundColor Green
    Write-Host " |  [8] " -NoNewline -ForegroundColor White; Write-Host "FAZER TUDO DE UMA VEZ (Opcoes 1 a 5)       " -ForegroundColor Yellow -NoNewline; Write-Host "   | " -ForegroundColor White
    Write-Host " |  [9] Sair                                                | " -ForegroundColor Red
    Write-Host " |__________________________________________________________| " -ForegroundColor Cyan
    Write-Host ""
}

function Remove-Bloatware {
    Write-Host "`n[!] Removendo Bloatware..." -ForegroundColor Yellow
    $apps = @("*Clipchamp*", "*Spotify*", "*Skype*", "*Zune*", "*3DBuilder*", "*MixedReality*", "*Disney*", "*Netflix*", "*TikTok*", "*OutlookForWindows*", "*FeedbackHub*", "*BingNews*", "*BingWeather*")
    foreach ($app in $apps) {
        Write-Host " -> Removendo: $app" -ForegroundColor Gray
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $app } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Bloatware removido." -ForegroundColor Green
}

function Remove-Xbox {
    Write-Host "`n[!] Removendo Xbox e corrigindo popups ms-gamingoverlay..." -ForegroundColor Yellow
    
    # 1. Desativar Game Bar e Game DVR via Registro
    Write-Host " -> Aplicando correcao de Registro para ms-gamingoverlay..." -ForegroundColor Gray
    $regPaths = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        "HKCU:\System\GameConfigStore"
    )
    foreach ($path in $regPaths) {
        if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    
    # 2. Remover pacotes Appx
    $xboxApps = @("*Xbox*", "*GamingOverlay*", "*XboxGameOverlay*", "*XboxIdentityProvider*", "*XboxSpeechToTextWrapper*")
    foreach ($xbox in $xboxApps) {
        Write-Host " -> Removendo: $xbox" -ForegroundColor Gray
        Get-AppxPackage -Name $xbox -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $xbox } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Host "[OK] Componentes Xbox removidos." -ForegroundColor Green
}

function Remove-OneDrive {
    Write-Host "`n[!] Eliminando OneDrive..." -ForegroundColor Yellow
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    $setup = if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" } else { "$env:SystemRoot\System32\OneDriveSetup.exe" }
    if (Test-Path $setup) { 
        Write-Host " -> Executando desinstalador..." -ForegroundColor Gray
        Start-Process $setup -ArgumentList "/uninstall" -NoNewWindow -Wait 
    }
    $regPaths = @("HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")
    foreach ($path in $regPaths) { if (Test-Path $path) { Set-ItemProperty -Path $path -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue } }
    Write-Host "[OK] OneDrive desinstalado e limpo." -ForegroundColor Green
}

function Disable-IA {
    Write-Host "`n[!] Desativando Cortana e Copilot..." -ForegroundColor Yellow
    Write-Host " -> Removendo pacotes Cortana..." -ForegroundColor Gray
    Get-AppxPackage -Name "*Microsoft.Windows.Cortana*" -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    $paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")
    foreach($p in $paths) { if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null } }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -ErrorAction SilentlyContinue
    Write-Host "[OK] IA desativada." -ForegroundColor Green
}

function Disable-Nagging {
    Write-Host "`n[!] Removendo avisos de Windows 11 e Conta Local..." -ForegroundColor Yellow
    
    # 1. Bloquear convite/forca do Windows 11
    Write-Host " -> Bloqueando avisos de upgrade para Windows 11..." -ForegroundColor Gray
    $osUpgradePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (!(Test-Path $osUpgradePath)) { New-Item -Path $osUpgradePath -Force | Out-Null }
    Set-ItemProperty -Path $osUpgradePath -Name "DisableOSUpgrade" -Value 1 -ErrorAction SilentlyContinue
    
    # 2. Desativar "Experiencia de Boas-vindas" e Nudging de Conta Microsoft
    Write-Host " -> Desativando avisos de Conta Local e 'Terminar configuracao'..." -ForegroundColor Gray
    $contentPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
    Set-ItemProperty -Path $contentPath -Name "SubscribedContent-310093Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $contentPath -Name "SubscribedContent-338388Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $contentPath -Name "SubscribedContent-338389Enabled" -Value 0 -ErrorAction SilentlyContinue
    
    # 3. Desativar Nudges de conta no Menu Iniciar
    $userProfilePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
    if (!(Test-Path $userProfilePath)) { New-Item -Path $userProfilePath -Force | Out-Null }
    Set-ItemProperty -Path $userProfilePath -Name "ScoobeSystemSettingEnabled" -Value 0 -ErrorAction SilentlyContinue
    
    Write-Host "[OK] Avisos bloqueados." -ForegroundColor Green
}

function Open-Activators {
    Write-Host "`n[!] Baixando e integrando ativadores externos... Aguarde." -ForegroundColor Magenta
    try {
        $remoteScript = Invoke-RestMethod https://get.activated.win
        Invoke-Expression $remoteScript
    } catch {
        Write-Host "`n[ERRO] Nao foi possivel conectar ao servidor remoto." -ForegroundColor Red
        Pause
    }
}

function Open-LocalProgram {
    # Caminho base do script (onde o .ps1 está)
    $scriptPath = $PSScriptRoot
    if ([string]::IsNullOrEmpty($scriptPath)) { $scriptPath = Get-Location }
    
    $exePath = Join-Path $scriptPath "Progama\Executavel.exe"
    
    if (Test-Path $exePath) {
        Write-Host "`n[!] Iniciando seu programa: Executavel.exe..." -ForegroundColor Green
        Start-Process $exePath
    } else {
        Write-Host "`n[ERRO] Programa nao encontrado em: $exePath" -ForegroundColor Red
        Write-Host "Certifique-se de que a pasta 'Progama' e o arquivo 'Executavel.exe' existem." -ForegroundColor Gray
        Pause
    }
}

do {
    Show-Menu
    $choice = Read-Host " Selecione uma opcao (1-9)"
    switch ($choice) {
        '1' { Remove-Bloatware }
        '2' { Remove-Xbox }
        '3' { Remove-OneDrive }
        '4' { Disable-IA }
        '5' { Disable-Nagging }
        '6' { Open-Activators }
        '7' { Open-LocalProgram }
        '8' { Remove-Bloatware; Remove-Xbox; Remove-OneDrive; Disable-IA; Disable-Nagging }
        '9' { exit }
        default { Write-Host " Opcao invalida!" -ForegroundColor Red }
    }
    if ($choice -ne '9' -and $choice -ne '6') { 
        Write-Host "`n Presione qualquer tecla para voltar ao menu..."
        $null = [System.Console]::ReadKey($true)
    }
} while ($choice -ne '9')
