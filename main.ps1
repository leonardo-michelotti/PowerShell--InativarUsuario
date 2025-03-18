[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory

# Carregar layout
if (Test-Path "./layout.ps1") {
    . .\layout.ps1
} else {
    [System.Windows.Forms.MessageBox]::Show(
        "Erro: Arquivo layout.ps1 não encontrado.",
        "Erro",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit
}

$ui = New-ADManagerLayout

# ========== CONFIGURAÇÕES ==========
$OUInativos = "OU=Inativos,OU=Baristo,DC=baristo,DC=local"
$logPath = "C:\Logs\ADManager.log"

# Criar diretório de logs se não existir
if (-not (Test-Path (Split-Path $logPath))) { 
    New-Item -Path (Split-Path $logPath) -ItemType Directory -Force | Out-Null
}

# ========== FUNÇÃO WRITE-LOG ==========
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('INFO','WARN','ERROR')]
        [string]$Level = 'INFO'
    )
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Exibe no console
    Write-Host $logMessage
    
    # Salva em arquivo
    Add-Content -Path $logPath -Value $logMessage
}

# ========== EVENTOS ==========
# Evento: Buscar Usuários
$ui.BtnBuscar.Add_Click({
    try {
        $ui.ListView.Items.Clear()
        $ui.StatusLabel.Text = "Buscando usuários..."
        $ui.ProgressBar.Value = 0
        $ui.Form.Refresh()

        # Obter parâmetros da busca
        $searchTerm = $ui.TxtBusca.Text.Trim()
        $status = $ui.CmbStatus.Text

        # Construir filtro de nome/login
        $nameFilter = ""
        if (-not [string]::IsNullOrEmpty($searchTerm)) {
            $nameFilter = "(|(Name=*$searchTerm*)(SamAccountName=*$searchTerm*))"
        }

        # Construir filtro de status
        $statusFilter = switch ($status) {
            "Ativos"   { "(Enabled=TRUE)" }
            "Inativos" { "(Enabled=FALSE)" }
            default    { "" }
        }

        # Combinar filtros corretamente
        $ldapFilter = "(objectClass=user)"
        if (-not [string]::IsNullOrEmpty($nameFilter) -and -not [string]::IsNullOrEmpty($statusFilter)) {
            $ldapFilter = "(&$nameFilter$statusFilter)"
        } elseif (-not [string]::IsNullOrEmpty($nameFilter)) {
            $ldapFilter = $nameFilter
        } elseif (-not [string]::IsNullOrEmpty($statusFilter)) {
            $ldapFilter = $statusFilter
        }

        Write-Log "Filtro LDAP gerado: $ldapFilter"

        # Executar busca com tratamento de erro
        try {
            $usuarios = @(Get-ADUser -LDAPFilter $ldapFilter -Properties * -ErrorAction Stop)
        } catch {
            throw "Erro ao buscar usuários no AD: $($_.Exception.Message)"
        }

        # Atualizar interface
        $ui.ProgressBar.Maximum = if ($usuarios.Count -gt 0) { $usuarios.Count } else { 1 }
        
        $contador = 0
        foreach ($u in $usuarios) {
            $item = New-Object System.Windows.Forms.ListViewItem($u.SamAccountName)
            $item.SubItems.Add($u.Name)
            $item.SubItems.Add($u.Enabled.ToString())
            $item.Tag = $u.DistinguishedName
            $ui.ListView.Items.Add($item)
            $ui.ProgressBar.Value = ++$contador
            $ui.Form.Refresh()
        }

        $ui.StatusLabel.Text = if ($usuarios.Count -gt 0) {
            "Busca concluída. $contador usuário(s) encontrado(s)"
        } else {
            "Nenhum resultado para '$searchTerm'"
        }
    }
    catch {
        $errorMessage = "Erro na busca: $($_.Exception.Message)"
        $ui.StatusLabel.Text = $errorMessage
        Write-Log "ERRO: $errorMessage" -Level ERROR
        [System.Windows.Forms.MessageBox]::Show(
            "Erro: $($_.Exception.Message)\nFiltro usado: $ldapFilter",
            "Erro",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
    }
    finally {
        $ui.ProgressBar.Value = 0
        $ui.BtnBuscar.Enabled = $true
    }
})

# Diretório onde o script está localizado
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$logDirectory = Join-Path $scriptDirectory "Logs"

# Criar pasta Logs se não existir
if (-not (Test-Path $logDirectory)) {
    New-Item -Path $logDirectory -ItemType Directory -Force | Out-Null
}

# ========== FUNÇÃO: LOG PARA USUÁRIOS ==========
function Write-UserLog {
    param(
        [string]$UserName,
        [string]$Message
    )
    $dataHora = (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
    $logUsuarioPath = Join-Path $logDirectory "ADManager_$UserName`_$dataHora.log"
    
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logUsuarioPath -Value $logMessage
}

# ========== EVENTO: INATIVAR E MOVER USUÁRIO ==========
$ui.BtnInativar.Add_Click({
    try {
        if ($ui.ListView.SelectedItems.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Nenhum usuário selecionado!", "Aviso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }
        
        $usuarioSelecionado = $ui.ListView.SelectedItems[0].Tag
        $usuarioNome = $ui.ListView.SelectedItems[0].SubItems[1].Text  # Obtém o nome do usuário
        
        Write-UserLog -UserName $usuarioNome -Message "===== Iniciando processo para usuário: $usuarioNome ($usuarioSelecionado) ====="

        # Desativar usuário
        Set-ADUser -Identity $usuarioSelecionado -Enabled $false
        Write-UserLog -UserName $usuarioNome -Message "Usuário inativado com sucesso."

        # Mover usuário para a OU Inativos
        $novoDestino = "OU=Inativos,OU=Baristo,DC=baristo,DC=local"
        Move-ADObject -Identity $usuarioSelecionado -TargetPath $novoDestino
        Write-UserLog -UserName $usuarioNome -Message "Usuário movido para a OU Inativos."

        Write-UserLog -UserName $usuarioNome -Message "===== Processo concluído com sucesso ====="
        [System.Windows.Forms.MessageBox]::Show("Usuário inativado e movido com sucesso!", "Sucesso", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $errorMessage = "Erro ao inativar/mover usuário: $($_.Exception.Message)"
        Write-UserLog -UserName $usuarioNome -Message "ERRO: $errorMessage"
        [System.Windows.Forms.MessageBox]::Show($errorMessage, "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})





# ========== INICIAR APLICAÇÃO ==========
[void]$ui.Form.ShowDialog()
