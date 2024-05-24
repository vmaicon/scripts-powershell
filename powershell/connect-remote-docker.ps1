if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Se não estiver sendo executado como administrador, reexecute o script com privilégios de administrador
    Write-Host "Este programa deve ser executado como administrador"
    exit 1
}

# Verificar se o OpenSSH está disponível
$opensshAvailable = (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*').Name -ne $null

if ($opensshAvailable) {
    Write-Host "OpenSSH já está instalado."
} else {
    # Instalar os componentes do cliente ssh
    Write-Host "OpenSSH não está disponível. Instalando os componentes do cliente ssh..."
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
}

# Perguntar ao usuário se ele deseja iniciar o serviço ssh-agent automaticamente
Write-Host
$startsshAgentAutomatically = Read-Host "Deseja iniciar o serviço ssh-agent automaticamente? (sim/[enter para não])"
if($startsshAgentAutomatically -eq 'sim'){
    $startsshAgentAutomatically = $true
}

Write-Host "Checando se o agente ssh está ativo"
Get-Service -Name ssh-agent
Write-Host

if ($startsshAgentAutomatically) {
    # Iniciar o serviço sshagent automaticamente
    Write-Host "Configurando para iniciar o serviço ssh-agent automaticamente..."
    Set-Service -StartupType Automatic
} else {
    # Iniciar o serviço ssh-agent manualmente
    Write-Host "Iniciando o serviço ssh-agent manualmente..."
    Start-Service ssh-agent
}
Write-Host

# Verificar se as regras de firewall estão configuradas
if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
    # Criar a regra de firewall 'OpenSSH-Server-In-TCP'
    Write-Host "Regra de firewall 'OpenSSH-Server-In-TCP' não existe, criando-a..."
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (ssh-agent)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Host "Regra de firewall 'OpenSSH-Server-In-TCP' já foi criada e existe."
}

Write-Host
Write-Host

# Antes de criar a pasta preciso verificar se ela já exsite
$sshPath = "$env:USERPROFILE\.ssh\id_ecdsa\"
if (-Not (Test-Path -Path $sshPath)) {
    New-Item -ItemType Directory -Path $sshPath -Force
    Write-Output "Pasta .ssh\id_ecdsa criada com sucesso."
} else {
    Write-Output "A pasta .ssh\id_ecdsa já existe."
}

Write-Host
Write-Host

# Criar um par de chaves SSH
Write-Host "Criando um par de chaves SSH..."
ssh-keygen -t ecdsa -b 521 -f $env:USERPROFILE\.ssh\id_ecdsa\id_ecdsa

# Mostrar o caminho do par de chaves
Write-Host "O par de chaves SSH foi criado em:"
Write-Host $env:USERPROFILE\.ssh\id_ecdsa\
Write-Host

# Adicona a chave criada ao ssh
Write-Host "Adicionando a chave privada ao ssh"
cd $env:USERPROFILE\.ssh\id_ecdsa\

ssh-add id_ecdsa
Write-Host

Write-Host "Verificando se a identidade do ssh-agent foi adicionada"
ssh-add -l

Write-Host
Write-Host
# Solicitar ao usuário que faça um teste SSH
Write-Host "Faça um teste SSH com o seguinte comando:"
Write-Host "ssh user@remote_server"

# Verificar se o Docker ou Docker Desktop está instalado
if (Test-Path -Path $env:ProgramFiles\Docker\Docker.exe) {
    Write-Host "Docker ou Docker Desktop já está instalado."

    # Criar o contexto Docker
    Write-Host "Criando o contexto Docker..."
    $dockerRemoteName = Read-Host "Nome remoto do Docker:"
    $dockerRemoteUserName = Read-Host "Nome do usuário remoto para conectar"
    $remoteHostWithPort = Read-Host "Host remoto com porta:"

    docker context create $dockerRemoteName --docker "host=ssh://$dockerRemoteUserName@$remoteHostWithPort"
} else {
    Write-Host "Docker ou Docker Desktop não está instalado. Instale-o para usar o contexto Docker."
}

Write-Host
Write-Host "Para usar no VSCODE instale as extensções abaixo"
Write-Host "Para executar este script, você precisará das seguintes extensões VSCode:"
Write-Host "  1. Remote Containers: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers"
Write-Host "  2. Remote SSH: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh"
Write-Host "  3. Remote Explorer: https://marketplace.visualstudio.com/"
Write-Host "  4. Remote Containers (opcional): https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers"

# Espera pela entrada de uma tecla antes de encerrar
Write-Host "Pressione qualquer tecla para encerrar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")