# Carregar bibliotecas necessárias
[Console]::OutputEncoding = [Text.UTF8Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory

# ---- CONFIGURAÇÕES ----
$OUInativos = "OU=Inativos,OU=Baristo,DC=baristo,DC=local"  # Ajustado conforme sua estrutura

# Cria formulário principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Gerenciador de Usuários AD"
$form.StartPosition = "CenterScreen"
$form.Size = New-Object System.Drawing.Size(600,400)
$form.AutoSize = $false
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $true

# Definir fonte padrão (opcional)
$fontePadrao = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Font = $fontePadrao

# ----- Label e TextBox para busca -----
$labelBusca = New-Object System.Windows.Forms.Label
$labelBusca.Text = "Nome do usuário:"
$labelBusca.AutoSize = $true
$labelBusca.Location = New-Object System.Drawing.Point(10,15)
$form.Controls.Add($labelBusca)

$textBoxBusca = New-Object System.Windows.Forms.TextBox
$textBoxBusca.Location = New-Object System.Drawing.Point(120,10)
$textBoxBusca.Size = New-Object System.Drawing.Size(320,25)
$form.Controls.Add($textBoxBusca)

# ----- Botão de busca -----
$buttonBuscar = New-Object System.Windows.Forms.Button
$buttonBuscar.Text = "Buscar"
$buttonBuscar.Location = New-Object System.Drawing.Point(450,10)
$buttonBuscar.Size = New-Object System.Drawing.Size(80,25)
$form.Controls.Add($buttonBuscar)

# ----- ListView para exibir resultados -----
$listView = New-Object System.Windows.Forms.ListView
$listView.View = "Details"
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Location = New-Object System.Drawing.Point(10,50)
$listView.Size = New-Object System.Drawing.Size(560,250)

# Configura colunas
$colLogin = $listView.Columns.Add("Login",100)
$colNome  = $listView.Columns.Add("Nome",300)
$colAtivo = $listView.Columns.Add("Ativo",80)

# Permitir que o ListView se expanda quando a janela for redimensionada
$listView.Anchor = 'Top, Left, Right, Bottom'

$form.Controls.Add($listView)

# ----- Botão para inativar selecionado -----
$buttonInativar = New-Object System.Windows.Forms.Button
$buttonInativar.Text = "Inativar Selecionado"
$buttonInativar.Location = New-Object System.Drawing.Point(200,320)
$buttonInativar.Size = New-Object System.Drawing.Size(200,30)
$buttonInativar.Enabled = $false
$buttonInativar.Anchor = 'Bottom'
$form.Controls.Add($buttonInativar)

# ========== EVENTOS ==========

# Evento: Buscar usuários ao clicar no botão "Buscar"
$buttonBuscar.Add_Click({
    $listView.Items.Clear()
    $nome = $textBoxBusca.Text.Trim()

    if ([string]::IsNullOrEmpty($nome)) {
        [System.Windows.Forms.MessageBox]::Show("Digite um nome para pesquisar.", 
            "Aviso", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    try {
        $usuarios = Get-ADUser -Filter "Name -like '*$nome*'" -Properties SamAccountName, Enabled, DistinguishedName
        if (!$usuarios) {
            [System.Windows.Forms.MessageBox]::Show("Nenhum usuário encontrado.", 
                "Resultado", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        }

        foreach ($u in $usuarios) {
            $item = New-Object System.Windows.Forms.ListViewItem($u.SamAccountName)
            $item.SubItems.Add($u.Name)
            $item.SubItems.Add($u.Enabled.ToString())  # Convertido para string
            $item.Tag = $u.DistinguishedName
            $listView.Items.Add($item)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao pesquisar usuários: $($_.Exception.Message)", 
            "Erro", 
            [System.Windows.Forms.MessageBoxButtons]::OK, 
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Evento: Habilita o botão "Inativar Selecionado" caso tenha algum item selecionado
$listView.Add_SelectedIndexChanged({
    if ($listView.SelectedItems.Count -gt 0) {
        $buttonInativar.Enabled = $true
    } else {
        $buttonInativar.Enabled = $false
    }
})

# Evento: Inativar o usuário selecionado ao clicar no botão "Inativar Selecionado"
$buttonInativar.Add_Click({
    if ($listView.SelectedItems.Count -eq 0) { return }
    
    $selecionado = $listView.SelectedItems[0]
    $sam = $selecionado.Text
    
    $resposta = [System.Windows.Forms.MessageBox]::Show(
        "Tem certeza que deseja desativar o usuário '$sam'?", 
        "Confirmação", 
        [System.Windows.Forms.MessageBoxButtons]::YesNo, 
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    if ($resposta -eq [System.Windows.Forms.DialogResult]::Yes) {
        try {
            # Atualiza o DN do usuário (para evitar DN desatualizado)
            $user = Get-ADUser -Identity $sam -Properties DistinguishedName
            $dn = $user.DistinguishedName

            # Verifica se a OU existe
            $ouExists = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUInativos'"
            if (!$ouExists) {
                [System.Windows.Forms.MessageBox]::Show("A OU 'Inativos' não existe.", "Erro", "OK", "Error")
                return
            }

            # Desativa a conta
            Disable-ADAccount -Identity $sam

            # Move para OU Inativos
            Move-ADObject -Identity $dn -TargetPath $OUInativos

            [System.Windows.Forms.MessageBox]::Show("Usuário '$sam' foi desativado e movido para a OU 'Inativos'.", 
                "Sucesso",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            )

            # Atualiza a linha no ListView
            $selecionado.SubItems[2].Text = "False"
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("Erro ao inativar ou mover usuário: $($_.Exception.Message)", 
                "Erro", 
                [System.Windows.Forms.MessageBoxButtons]::OK, 
                [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
})

# Mostrar o formulário
[void] $form.ShowDialog()