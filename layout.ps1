# layout.ps1
function New-ADManagerLayout {
    # ========== CONFIGURAÇÕES DE CORES ==========
    $colors = @{
        Primary   = [System.Drawing.Color]::FromArgb(255, 165, 0)   # Laranja
        Secondary = [System.Drawing.Color]::FromArgb(64, 64, 64)    # Cinza escuro
        Background = [System.Drawing.Color]::FromArgb(40, 40, 40)   # Fundo escuro
        Text       = [System.Drawing.Color]::White
    }

    # ========== FORMULÁRIO PRINCIPAL ==========
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Gerenciador de Usuários AD"
    $form.StartPosition = "CenterScreen"
    $form.Size = New-Object System.Drawing.Size(800, 600)
    $form.BackColor = $colors.Background
    $form.ForeColor = $colors.Text
    $form.Font = New-Object System.Drawing.Font("Segoe UI", 10)
    $form.MaximizeBox = $false

    # ========== CONTROLES PRINCIPAIS ==========
    $mainPanel = New-Object System.Windows.Forms.Panel
    $mainPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $mainPanel.Padding = New-Object System.Windows.Forms.Padding(20)

    # Grupo de Busca
    $grpBusca = New-Object System.Windows.Forms.GroupBox
    $grpBusca.Text = " Pesquisar Usuários "
    $grpBusca.Size = New-Object System.Drawing.Size(740, 100)
    $grpBusca.Location = New-Object System.Drawing.Point(30, 20)
    $grpBusca.ForeColor = $colors.Primary
    $grpBusca.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $grpBusca.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)

    # Componentes do Grupo de Busca
    $txtBusca = New-Object System.Windows.Forms.TextBox
    $txtBusca.Location = New-Object System.Drawing.Point(20, 30)
    $txtBusca.Size = New-Object System.Drawing.Size(400, 30)
    $txtBusca.BackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
    $txtBusca.ForeColor = $colors.Text

    $cmbStatus = New-Object System.Windows.Forms.ComboBox
    $cmbStatus.Items.AddRange(@("Todos", "Ativos", "Inativos"))
    $cmbStatus.SelectedIndex = 0
    $cmbStatus.Location = New-Object System.Drawing.Point(440, 30)
    $cmbStatus.Size = New-Object System.Drawing.Size(150, 30)
    $cmbStatus.BackColor = $txtBusca.BackColor
    $cmbStatus.ForeColor = $colors.Text

    $btnBuscar = New-Object System.Windows.Forms.Button
    $btnBuscar.Text = "Buscar"
    $btnBuscar.Size = New-Object System.Drawing.Size(120, 30)
    $btnBuscar.Location = New-Object System.Drawing.Point(610, 30)
    $btnBuscar.BackColor = $colors.Primary
    $btnBuscar.ForeColor = $colors.Text
    $btnBuscar.FlatStyle = "Flat"
    $btnBuscar.FlatAppearance.BorderSize = 1
    $btnBuscar.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200, 200, 200)

    # Lista de Resultados
    $listView = New-Object System.Windows.Forms.ListView
    $listView.View = "Details"
    $listView.FullRowSelect = $true
    $listView.Size = New-Object System.Drawing.Size(740, 300)
    $listView.Location = New-Object System.Drawing.Point(30, 130)
    $listView.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $listView.ForeColor = $colors.Text
    $listView.Columns.Add("Login", 150) | Out-Null
    $listView.Columns.Add("Nome", 350) | Out-Null
    $listView.Columns.Add("Status", 100) | Out-Null

    # Barra de Progresso
    $progressBar = New-Object System.Windows.Forms.ProgressBar
    $progressBar.Size = New-Object System.Drawing.Size(740, 20)
    $progressBar.Location = New-Object System.Drawing.Point(30, 440)
    $progressBar.Style = "Continuous"

    # Botão Inativar
    $btnInativar = New-Object System.Windows.Forms.Button
    $btnInativar.Text = "Inativar Selecionado"
    $btnInativar.Size = New-Object System.Drawing.Size(180, 35)
    $btnInativar.Location = New-Object System.Drawing.Point(310, 480)
    $btnInativar.BackColor = [System.Drawing.Color]::FromArgb(200, 60, 60)
    $btnInativar.ForeColor = $colors.Text
    $btnInativar.FlatStyle = "Flat"
    $btnInativar.FlatAppearance.BorderSize = 1
    $btnInativar.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(200, 200, 200)

    # Barra de Status
    $statusBar = New-Object System.Windows.Forms.StatusStrip
    $statusBar.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
    $statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
    $statusBar.Items.Add($statusLabel) | Out-Null

    # ========== MONTAGEM DA INTERFACE ==========
    $grpBusca.Controls.AddRange(@($txtBusca, $cmbStatus, $btnBuscar))
    $mainPanel.Controls.AddRange(@($grpBusca, $listView, $progressBar, $btnInativar))
    $form.Controls.AddRange(@($mainPanel, $statusBar))

    # Retornar componentes importantes
    return @{
        Form = $form
        TxtBusca = $txtBusca
        CmbStatus = $cmbStatus
        BtnBuscar = $btnBuscar
        ListView = $listView
        ProgressBar = $progressBar
        BtnInativar = $btnInativar
        StatusLabel = $statusLabel
    }
}