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

# ==============================================================================
# FUNCOES DE APOIO E ANIMACAO
# ==============================================================================

function Show-Spinner {
    param([string]$Message)
    $spinner = @('|', '/', '-', '\')
    for ($i = 0; $i -lt 10; $i++) {
        foreach ($char in $spinner) {
            Write-Host -NoNewline "`r [$char] $Message" -ForegroundColor Yellow
            Start-Sleep -Milliseconds 50
        }
    }
    Write-Host "`r [OK] $Message" -ForegroundColor Green
}

function Check-RestorePoint {
    Write-Host "`n[?] Verificando Pontos de Restauracao..." -ForegroundColor Cyan
    $lastRP = Get-ComputerRestorePoint | Sort-Object SequenceNumber -Descending | Select-Object -First 1
    $createNew = $false
    if ($null -eq $lastRP) {
        Write-Host " [!] Nenhum Ponto de Restauracao encontrado no sistema." -ForegroundColor Yellow
        $createNew = $true
    } else {
        try {
            $creationTime = [datetime]::Parse($lastRP.CreationTime)
            $age = (Get-Date) - $creationTime
            if ($age.TotalHours -gt 24) {
                Write-Host " [!] O ultimo Ponto de Restauracao tem mais de 24 horas." -ForegroundColor Yellow
                $createNew = $true
            } else {
                Write-Host " [OK] Ponto de Restauracao recente detectado (" -NoNewline -ForegroundColor Green; Write-Host "$($lastRP.Description)" -NoNewline -ForegroundColor White; Write-Host ")." -ForegroundColor Green
                return
            }
        } catch { $createNew = $true }
    }
    if ($createNew) {
        $choice = Read-Host " -> Deseja criar um novo Ponto de Restauracao agora por seguranca? (S/N)"
        if ($choice -eq 'S' -or $choice -eq 's') {
            $rpName = Read-Host " -> Digite um nome para o ponto (ou Enter para 'Antes do Otimizador')"
            if ([string]::IsNullOrWhiteSpace($rpName)) { $rpName = "Antes do Otimizador" }
            Write-Host " [!] Criando Ponto de Restauracao '$rpName'... Aguarde." -ForegroundColor Yellow
            try {
                Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
                Checkpoint-Computer -Description $rpName -RestorePointType "MODIFY_SETTINGS"
                Write-Host " [OK] Ponto de Restauracao criado com sucesso!" -ForegroundColor Green
            } catch { Write-Host " [ERRO] Nao foi possivel criar o ponto automaticamente." -ForegroundColor Red }
        } else { Write-Host " [!] Ignorando criacao de ponto de seguranca." -ForegroundColor Gray }
    }
}

# ==============================================================================
# MENU E INTERFACE
# ==============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "  __________________________________________________________  " -ForegroundColor Cyan
    Write-Host " |                                                          | " -ForegroundColor Cyan
    Write-Host " |                  OTIMIZADOR DO WINDOWS                   | " -ForegroundColor Cyan
    Write-Host " |__________________________________________________________| " -ForegroundColor Cyan
    Write-Host " |                                                          | " -ForegroundColor Cyan
    Write-Host " |  [1] Remover Aplicativos Inuteis (Bloatware)             | " -ForegroundColor White
    Write-Host " |  [2] Realizar Configuracoes Iniciais                     | " -ForegroundColor White
    Write-Host " |  [3] Desinstalar o OneDrive                              | " -ForegroundColor White
    Write-Host " |  [4] Bloquear Avisos de Win11 e Conta Local              | " -ForegroundColor White
    Write-Host " |  [5] Limpeza de Lixo e Cache do Sistema                  | " -ForegroundColor White
    Write-Host " |  [6] Desativar Telemetria e Coleta de Dados              | " -ForegroundColor White
    Write-Host " |  [7] ativar windows / office                             | " -ForegroundColor White
    Write-Host " |  [8] Abrir Ferramenta Personalizada                      | " -ForegroundColor White
    Write-Host " |  [9] Ajustar Efeitos Visuais para Desempenho            | " -ForegroundColor White
    Write-Host " |  [10] Otimizar Servicos do Sistema                       | " -ForegroundColor White
    Write-Host " |  [11] Atualizar Drivers do Sistema                       | " -ForegroundColor White
    Write-Host " |  [12] Executar otimizacao automaticamente                | " -ForegroundColor White
    Write-Host " |  [13] REVERTER ALTERACOES                                | " -ForegroundColor White
    Write-Host " |  [14] Sair                                               | " -ForegroundColor Red
    Write-Host " |__________________________________________________________| " -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# MODULOS DE OTIMIZACAO
# ==============================================================================

function Restore-System {
    Write-Host "`n[!] Iniciando modulo de Reversao..." -ForegroundColor Magenta
    $restorePoints = Get-ComputerRestorePoint
    if ($null -eq $restorePoints) {
        Write-Host " [ERRO] Nenhum ponto de restauracao encontrado para reverter." -ForegroundColor Red
        return
    }
    
    Write-Host " Pontos de Restauracao disponiveis:" -ForegroundColor Cyan
    $restorePoints | Select-Object SequenceNumber, Description, CreationTime | Out-Host
    
    $sn = Read-Host "`n -> Digite o Numero (SequenceNumber) do ponto que deseja restaurar (ou Enter para cancelar)"
    if (![string]::IsNullOrWhiteSpace($sn)) {
        Write-Host " [!!!] O sistema sera reiniciado para aplicar a restauracao. Salve tudo agora!" -ForegroundColor Red
        $confirm = Read-Host " -> Tem certeza que deseja restaurar para o ponto $sn? (S/N)"
        if ($confirm -eq 'S' -or $confirm -eq 's') {
            Restore-Computer -RestorePoint $sn
        }
    }
}

function Optimize-VisualEffects {
    Check-RestorePoint
    Show-Spinner "Otimizando efeitos visuais para desempenho..."
    $visualPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (!(Test-Path $visualPath)) { New-Item -Path $visualPath -Force | Out-Null }
    Set-ItemProperty -Path $visualPath -Name "VisualFXSetting" -Value 2
    $desktopPath = "HKCU:\Control Panel\Desktop"
    Set-ItemProperty -Path $desktopPath -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value 0 -ErrorAction SilentlyContinue
    Write-Host " [OK] Efeitos visuais ajustados! (Necessario reiniciar)" -ForegroundColor Green
}

function Optimize-Services {
    Check-RestorePoint
    Show-Spinner "Otimizando servicos do sistema..."
    
    $services = @(
        "DiagTrack",        # Telemetria
        "dmwappushservice", # WAP Push
        "RemoteRegistry",   # Registro Remoto
        "MapsBroker",       # Mapas
        "WbioSrvc"          # Biometria
    )

    foreach ($svc in $services) {
        if (Get-Service -Name $svc -ErrorAction SilentlyContinue) {
            Write-Host " -> Desativando: $svc" -ForegroundColor Gray
            Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        }
    }

    # Pergunta sobre SysMain (Superfetch)
    Write-Host "`n[?] O SysMain (Superfetch) ajuda no carregamento, mas pode pesar no disco." -ForegroundColor Cyan
    $sysMainChoice = Read-Host " -> Deseja DESATIVAR o SysMain? (Recomendado apenas para SSD com +8GB RAM) (S/N)"
    if ($sysMainChoice -eq 'S' -or $sysMainChoice -eq 's') {
        Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host " -> SysMain desativado." -ForegroundColor Gray
    }
    
    # Pergunta sobre impressora
    Write-Host "`n[?] Uso de Impressora: Se voce tem uma impressora instalada, responda 'S'." -ForegroundColor Cyan
    $printChoice = Read-Host " -> Voce usa ou pretende usar impressora neste PC? (S/N)"
    if ($printChoice -eq 'N' -or $printChoice -eq 'n') {
        Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "Spooler" -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host " -> Spooler de Impressao desativado." -ForegroundColor Gray
    } else {
        Write-Host " -> Mantendo servicos de impressora ativos." -ForegroundColor Green
    }

    Write-Host " [OK] Servicos otimizados." -ForegroundColor Green
}

function Update-Drivers {
    Write-Host "`n[!] Verificando atualizacoes de drivers via winget..." -ForegroundColor Yellow
    winget upgrade --include-unknown --accept-package-agreements --accept-source-agreements
    Write-Host " [OK] Processo de atualizacao finalizado." -ForegroundColor Green
}

function Remove-Bloatware {
    Check-RestorePoint
    Write-Host "`n[!] Removendo Aplicativos Inuteis (Bloatware)..." -ForegroundColor Yellow
    $apps = @(
        "*Clipchamp*", "*Spotify*", "*Skype*", "*Zune*", "*3DBuilder*", "*MixedReality*", 
        "*Disney*", "*Netflix*", "*TikTok*", "*OutlookForWindows*", "*Microsoft.OutlookForWindows*", 
        "*FeedbackHub*", "*BingNews*", "*BingWeather*", "*YourPhone*", "*PowerAutomate*", "*ToDo*",
        "*Print3D*", "*Office.OneNote*", "*OneConnect*", "*Maps*", "*GetHelp*", "*GetStarted*", 
        "*Office.Messenger*", "*SolitaireCollection*", "*People*", "*Wallet*", "*OneNote*", 
        "*StickyNotes*", "*MixedReality.Portal*", "*SoundRecorder*", 
        "*CommunicationApps*", "*WindowsAlarms*", 
        "*WindowsMaps*", "*WindowsSoundRecorder*", "*ZuneMusic*", "*ZuneVideo*", "*BingFoodAndDrink*",
        "*BingHealthAndFitness*", "*BingTravel*", "*BingFinance*", "*BingSports*",
        "*MicrosoftEdgeDevToolsClient*", "*Microsoft365*", "*Sway*", "*Whiteboard*",
        "*MicrosoftOfficeHub*", "*Microsoft.Getoffice*", "*Office.Desktop*", "*Microsoft.Office.Desktop*"
    )
    foreach ($app in $apps) {
        Write-Host -NoNewline "`r -> Removendo: $app..." -ForegroundColor Gray
        Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $app } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Host "`n [OK] Faxina de bloatware concluida." -ForegroundColor Green
}

function Install-Essentials {
    Write-Host "`n[?] Qual navegador voce deseja instalar?" -ForegroundColor Cyan
    Write-Host " [1] Google Chrome"
    Write-Host " [2] Brave Browser"
    Write-Host " [3] Pular navegadores"
    $browserChoice = Read-Host " Selecione (1-3)"
    $packageId = ""
    if ($browserChoice -eq '1') { $packageId = "Google.Chrome" }
    elseif ($browserChoice -eq '2') { $packageId = "Brave.Brave" }
    if ($packageId -ne "") {
        Write-Host " [!] Instalando navegador via winget... isso pode demorar." -ForegroundColor Yellow
        winget install --id $packageId --silent --accept-package-agreements --accept-source-agreements
    }
    $vlcChoice = Read-Host "`n -> Deseja instalar o VLC Media Player? (S/N)"
    if ($vlcChoice -eq 'S' -or $vlcChoice -eq 's') {
        Write-Host " [!] Instalando VLC Player via winget..." -ForegroundColor Yellow
        winget install --id VideoLAN.VLC --silent --accept-package-agreements --accept-source-agreements
    }
    Write-Host "`n [OK] Configuracoes concluidas." -ForegroundColor Green
}

function Remove-Xbox {
    Show-Spinner "Limpando funcoes de jogos..."
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    $xboxApps = @("*Xbox*", "*GamingOverlay*", "*XboxGameOverlay*", "*XboxIdentityProvider*", "*XboxSpeechToTextWrapper*")
    foreach ($xbox in $xboxApps) {
        Get-AppxPackage -Name $xbox -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like $xbox } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
}

function Remove-OneDrive {
    Check-RestorePoint
    Show-Spinner "Desinstalando OneDrive..."
    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
    $setup = if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" } else { "$env:SystemRoot\System32\OneDriveSetup.exe" }
    if (Test-Path $setup) { Start-Process $setup -ArgumentList "/uninstall" -NoNewWindow -Wait }
    $regPaths = @("HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}", "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")
    foreach ($path in $regPaths) { if (Test-Path $path) { Set-ItemProperty -Path $path -Name "System.IsPinnedToNameSpaceTree" -Value 0 -ErrorAction SilentlyContinue } }
}

function Disable-IA {
    Show-Spinner "Desativando Cortana e Copilot..."
    Get-AppxPackage -Name "*Microsoft.Windows.Cortana*" -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue
    $paths = @("HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search", "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot")
    foreach($p in $paths) { if (!(Test-Path $p)) { New-Item -Path $p -Force | Out-Null } }
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name "TurnOffWindowsCopilot" -Value 1
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -ErrorAction SilentlyContinue
}

function Disable-Nagging {
    Check-RestorePoint
    Show-Spinner "Bloqueando avisos do sistema..."
    $osUpgradePath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    if (!(Test-Path $osUpgradePath)) { New-Item -Path $osUpgradePath -Force | Out-Null }
    Set-ItemProperty -Path $osUpgradePath -Name "DisableOSUpgrade" -Value 1 -ErrorAction SilentlyContinue
    $userProfilePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement"
    if (!(Test-Path $userProfilePath)) { New-Item -Path $userProfilePath -Force | Out-Null }
    Set-ItemProperty -Path $userProfilePath -Name "ScoobeSystemSettingEnabled" -Value 0 -ErrorAction SilentlyContinue
}

function Clean-SystemWaste {
    Check-RestorePoint
    Show-Spinner "Limpando lixo e cache..."
    $paths = @("$env:TEMP\*", "C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Windows\SoftwareDistribution\Download\*")
    foreach ($path in $paths) { Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue }
}

function Disable-Telemetry {
    Check-RestorePoint
    Show-Spinner "Desativando telemetria..."
    $services = @("DiagTrack", "dmwappushservice")
    foreach ($s in $services) { 
        Stop-Service -Name $s -ErrorAction SilentlyContinue
        Set-Service -Name $s -StartupType Disabled -ErrorAction SilentlyContinue
    }
    $telemetryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (!(Test-Path $telemetryPath)) { New-Item -Path $telemetryPath -Force | Out-Null }
    Set-ItemProperty -Path $telemetryPath -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
}

function Open-Activators {
    Write-Host "`n[!] Iniciando ativador integrado..." -ForegroundColor Magenta
    try {
        $remoteScript = Invoke-RestMethod https://get.activated.win
        Invoke-Expression $remoteScript
    } catch {
        Write-Host "`n[ERRO] Nao foi possivel conectar ao servidor remoto." -ForegroundColor Red
        Pause
    }
}

function Open-LocalProgram {
    $scriptPath = if ($PSScriptRoot) { $PSScriptRoot } else { Get-Location }
    $exePath = Join-Path $scriptPath "Progama\Executavel.exe"
    if (Test-Path $exePath) {
        Start-Process $exePath
    } else {
        Write-Host "`n[ERRO] Ferramenta nao encontrada." -ForegroundColor Red
        Pause
    }
}

# ==============================================================================
# LOOP PRINCIPAL
# ==============================================================================

do {
    Show-Menu
    $choice = Read-Host " Selecione uma opcao (1-14)"
    switch ($choice) {
        '1' { Remove-Bloatware }
        '2' { Check-RestorePoint; Remove-Xbox; Disable-IA; Install-Essentials }
        '3' { Remove-OneDrive }
        '4' { Disable-Nagging }
        '5' { Clean-SystemWaste }
        '6' { Disable-Telemetry }
        '7' { Open-Activators }
        '8' { Open-LocalProgram }
        '9' { Optimize-VisualEffects }
        '10' { Optimize-Services }
        '11' { Update-Drivers }
        '12' { Check-RestorePoint; Remove-Bloatware; Remove-Xbox; Disable-IA; Remove-OneDrive; Disable-Nagging; Clean-SystemWaste; Disable-Telemetry }
        '13' { Restore-System }
        '14' { exit }
        default { Write-Host " Opcao invalida!" -ForegroundColor Red }
    }
    if ($choice -ne '14' -and $choice -ne '7') { 
        Write-Host "`n Presione qualquer tecla para voltar ao menu..."
        $null = [System.Console]::ReadKey($true)
    }
} while ($choice -ne '14')
