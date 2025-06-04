Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Form principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Desinstalar Programa em Computadores Remotos"
$form.Size = New-Object System.Drawing.Size(700, 600)
$form.StartPosition = "CenterScreen"

# Campo: lista de computadores (um por linha)
$lblPC = New-Object System.Windows.Forms.Label
$lblPC.Text = "Digite os nomes dos computadores (um por linha):"
$lblPC.Location = New-Object System.Drawing.Point(10, 10)
$lblPC.AutoSize = $true
$form.Controls.Add($lblPC)

$txtPCs = New-Object System.Windows.Forms.TextBox
$txtPCs.Multiline = $true
$txtPCs.ScrollBars = "Vertical"
$txtPCs.Location = New-Object System.Drawing.Point(10, 30)
$txtPCs.Size = New-Object System.Drawing.Size(300, 100)
$form.Controls.Add($txtPCs)

# Credenciais
$lblUsuario = New-Object System.Windows.Forms.Label
$lblUsuario.Text = "Usuário:"
$lblUsuario.Location = New-Object System.Drawing.Point(330, 30)
$form.Controls.Add($lblUsuario)

$txtUsuario = New-Object System.Windows.Forms.TextBox
$txtUsuario.Location = New-Object System.Drawing.Point(400, 30)
$txtUsuario.Width = 250
$form.Controls.Add($txtUsuario)

$lblSenha = New-Object System.Windows.Forms.Label
$lblSenha.Text = "Senha:"
$lblSenha.Location = New-Object System.Drawing.Point(330, 70)
$form.Controls.Add($lblSenha)

$txtSenha = New-Object System.Windows.Forms.MaskedTextBox
$txtSenha.PasswordChar = '*'
$txtSenha.Location = New-Object System.Drawing.Point(400, 70)
$txtSenha.Width = 250
$form.Controls.Add($txtSenha)

# Botão: buscar programas
$btnBuscar = New-Object System.Windows.Forms.Button
$btnBuscar.Text = "Buscar Programas"
$btnBuscar.Location = New-Object System.Drawing.Point(10, 140)
$form.Controls.Add($btnBuscar)

# ListBox de programas
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 180)
$listBox.Size = New-Object System.Drawing.Size(660, 280)
$form.Controls.Add($listBox)

# Botão: desinstalar
$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "Desinstalar Programa Selecionado"
$btnUninstall.Location = New-Object System.Drawing.Point(10, 470)
$form.Controls.Add($btnUninstall)

# Label de status
$status = New-Object System.Windows.Forms.Label
$status.Location = New-Object System.Drawing.Point(10, 510)
$status.Size = New-Object System.Drawing.Size(660, 30)
$form.Controls.Add($status)

# Função para converter senha em credential
function Get-Cred($user, $pass) {
    $secure = ConvertTo-SecureString $pass -AsPlainText -Force
    return New-Object System.Management.Automation.PSCredential ($user, $secure)
}

# Buscar programas remotamente
$btnBuscar.Add_Click({
    $listBox.Items.Clear()
    $status.Text = "Buscando programas..."
    $pcs = $txtPCs.Text -split "`r?`n" | Where-Object { $_ -ne "" }
    $user = $txtUsuario.Text
    $pass = $txtSenha.Text
    $cred = Get-Cred $user $pass

    foreach ($pc in $pcs) {
        try {
            $apps = Invoke-Command -ComputerName $pc -Credential $cred -ScriptBlock {
                Get-WmiObject -Class Win32_Product | Select-Object Name
            }
            $listBox.Items.Add("--- [$pc] ---")
            foreach ($app in $apps) {
                if ($app.Name) {
                    $listBox.Items.Add("$pc :: $($app.Name)")
                }
            }
        } catch {
            $listBox.Items.Add("Erro ao acessar $pc $($_)")
        }
    }

    $status.Text = "Busca finalizada."
})

# Desinstalar programa
$btnUninstall.Add_Click({
    $item = $listBox.SelectedItem
    if (-not $item -or $item -notmatch "^(.*) :: (.*)$") {
        [System.Windows.Forms.MessageBox]::Show("Selecione um programa válido.")
        return
    }

    $selectedMatch = $null
    [void]($item -match "^(.*) :: (.*)$")
    $pc = $matches[1]
    $programa = $matches[2]
    $cred = Get-Cred $txtUsuario.Text $txtSenha.Text

    $confirm = [System.Windows.Forms.MessageBox]::Show("Deseja desinstalar '$programa' de $pc?", "Confirmar", "YesNo")
    if ($confirm -ne "Yes") { return }

    $status.Text = "Desinstalando $programa em $pc..."

    try {
        $result = Invoke-Command -ComputerName $pc -Credential $cred -ScriptBlock {
            param($prog)
            $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $prog }
            if ($app) {
                $app.Uninstall() | Out-Null
                return "'$prog' desinstalado com sucesso."
            } else {
                return "Programa não encontrado: $prog"
            }
        } -ArgumentList $programa

        $status.Text = $result
    } catch {
        $status.Text = "Erro: $_"
    }
})

# Exibir o formulário
[void]$form.ShowDialog()