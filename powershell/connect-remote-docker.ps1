
function InstallOpenSSHClient {

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Se não estiver sendo executado como administrador, reexecute o script com privilégios de administrador
        Write-Host "Este programa deve ser executado como administrador"
        exit 1
    }
    
    # Verificar se o OpenSSH está disponível
    $opensshAvailable = $null -ne (Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*').Name
    
    if ($opensshAvailable) {
        Write-Host "OpenSSH já está instalado."
    } else {
        # Instalar os componentes do cliente ssh
        Write-Host "OpenSSH não está disponível. Instalando os componentes do cliente ssh..."
        Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
    }
    
    exit 0
    
}

function HabilitaInicializacaoDoServicoSSH {
    
    # Perguntar ao usuário se ele deseja iniciar o serviço ssh-agent automaticamente
    Write-Host
    $startsshAgentAutomatically = Read-Host "Deseja iniciar o serviço ssh-agent automaticamente? (sim/[enter para não])"
    if($startsshAgentAutomatically -eq "sim"){
        $startsshAgentAutomatically = $true
    }
    
    if ($startsshAgentAutomatically) {
        # Iniciar o serviço ssha-gent automaticamente
        Write-Host "Configurando para iniciar o serviço ssh-agent automaticamente..."
        Set-Service -StartupType Automatic ssh-agent
    } else {
        # Iniciar o serviço ssh-agent manualmente
        Write-Host "Iniciando o serviço ssh-agent manualmente..."
        Start-Service ssh-agent
    }
    
}

function HabilitaRegraDoFirewall {

    # Verificar se as regras de firewall estão configuradas
    if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue | Select-Object Name, Enabled)) {
        # Criar a regra de firewall 'OpenSSH-Server-In-TCP'
        Write-Host "Regra de firewall 'OpenSSH-Server-In-TCP' não existe, criando-a..."
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (ssh-agent)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    } else {
        Write-Host "Regra de firewall 'OpenSSH-Server-In-TCP' já foi criada e existe."
    }
}

function CriarDockerContext ($dockerRemoteUserName, $remoteHost) {
    # Verificar se o Docker ou Docker Desktop está instalado
    if (Test-Path -Path $env:ProgramFiles\Docker\Doker\resource\bin\docker) {
        Write-Host "Docker ou Docker Desktop já está instalado."

        # Criar o contexto Docker
        Write-Host "Criando o contexto Docker..."
        $dockerRemoteName = Read-Host "Nome remoto do Docker:"
        Write-Host

        docker context create $dockerRemoteName --docker "host=ssh://$dockerRemoteUserName@$remoteHost"
    }
    else {
        Write-Host "Docker ou Docker Desktop não está instalado. Instale-o para usar o contexto Docker."
        Write-Host
    }
}

function CriarPastaSsh {
    
    # Antes de criar a pasta preciso verificar se ela já exsite
    $sshPath = "$env:USERPROFILE\.ssh\id_ecdsa\"
    if (-Not (Test-Path -Path $sshPath)) {
        New-Item -ItemType Directory -Path $sshPath -Force
        Write-Output "Pasta .ssh\id_ecdsa criada com sucesso."
    } else {
        Write-Output "A pasta .ssh\id_ecdsa já existe."
    }
    
}

function VerificaConexaoSSH ($ServidorRemoto) {
    $app = "ssh"
    $argumentList = -o BatchMode=yes $env:USERNAME@$ServidorRemoto exit # sai assim que a conexão é estabelecida

    try {
        
        $processo = Start-Process -FilePath $app -ArgumentList $argumentList -Wait -NoNewWindow -PassThru
    
        if($processo.ExitCode -eq 0){
            Write-Host "Teste de conexão bem sucedido!"
        }
    }
    catch {
        Write-Host $processo.ExitCode
    }
    
}

function GerarParDeChave {
    # Criar um par de chaves SSH
    Write-Host "Criando um par de chaves SSH..."
    ssh-keygen -t ecdsa -b 521 -f $env:USERPROFILE\.ssh\id_ecdsa\id_ecdsa

    # Mostrar o caminho do par de chaves
    Write-Host "O par de chaves SSH foi criado em:"
    Write-Host $env:USERPROFILE\.ssh\id_ecdsa\
    Write-Host

    # Adicona a chave criada ao ssh
    Write-Host "Adicionando a chave privada ao ssh"
    Set-Location $env:USERPROFILE\.ssh\id_ecdsa\

    ssh-add id_ecdsa
    Write-Host

    Write-Host "Verificando se a identidade do ssh-agent foi adicionada"
    ssh-add -l
    
}

function InformacoesAdicionais {

    Write-Host "Envie a chave pública ao administrador do servidor para adicionar no host que irá se conectar"
    Write-Host "A chave pública de ser adicionada ao .ssh/authorized_keys do servidor, use o comando sudo nano .ssh/authorized_keys"
    Write-Host
    Write-Host "Certifiquei-se de que seu usuário tem permissão de acesso aos comandos docker: sudo usermod -aG docker `$(whoami)"
    Write-Host
    Write-Host "Para usar no VSCODE instale as extensções abaixo"
    Write-Host "Para executar este script, você precisará das seguintes extensões VSCode:"
    Write-Host "  1. Remote Containers: ms-vscode-remote.remote-containers"
    Write-Host "  2. Remote SSH: ms-vscode-remote.remote-ssh"
    
}

# Verificar as dependencias, openshh e docker

Write-Host "Verificando se o OpenSSH.Client está ativo"

if ((Get-Service -Name ssh-agent).Status -eq "Running"){
    Write-Host "Serviço ssh-agent ativo"
    HabilitaInicializacaoDoServicoSSH
    HabilitaRegraDoFirewall
    
}else{
    Write-Host "Serviço ssh não está ativo..."
    Write-Host "Checando a instalação..."
    Write-Host "Isto requer elevação de nível para administrador..."
    InstallOpenSSHClient
}

# Criando as pastas para o par de chaves
Write-Host "Criando a pasta .ssh"
CriarPastaSsh

GerarParDeChave

# Teste de conexão ssh
$servidorRemoto = Read-Host "Informe o ip do servidor remoto: "

Write-Host "Verifiando a conexão ssh com o servidor remoto"
VerificaConexaoSSH -ServidorRemoto $servidorRemoto

# Criando o docker context
Write-Host "Criando uma conexão com o contexto docker"
CriarDockerContext -dockerRemoteUserName $env:USERNAME -remoteHostWithPort $servidorRemoto

InformacoesAdicionais

# Espera pela entrada de uma tecla antes de encerrar
Write-Host "Pressione qualquer tecla para encerrar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
