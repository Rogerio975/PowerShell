# ...existing code...

# Label e campo para usuário
$labelUser = New-Object System.Windows.Forms.Label
$labelUser.Text = "Usuário (domínio\usuário):"
$labelUser.Location = New-Object System.Drawing.Point(20, 55)
$labelUser.AutoSize = $true
$form.Controls.Add($labelUser)

$txtUser = New-Object System.Windows.Forms.TextBox
$txtUser.Location = New-Object System.Drawing.Point(200, 53)
$txtUser.Width = 300
$form.Controls.Add($txtUser)

# Label e campo para senha
$labelPass = New-Object System.Windows.Forms.Label
$labelPass.Text = "Senha:"
$labelPass.Location = New-Object System.Drawing.Point(20, 85)
$labelPass.AutoSize = $true
$form.Controls.Add($labelPass)

$txtPass = New-Object System.Windows.Forms.TextBox
$txtPass.Location = New-Object System.Drawing.Point(200, 83)
$txtPass.Width = 300
$txtPass.UseSystemPasswordChar = $true
$form.Controls.Add($txtPass)

# Ajusta posição dos outros controles
$btnBuscar.Location = New-Object System.Drawing.Point(200, 115)
$listBox.Location = New-Object System.Drawing.Point(20, 150)

# Evento: Buscar programas
$btnBuscar.Add_Click({
    $listBox.Items.Clear()
    $pc = $txtPC.Text
    $user = $txtUser.Text
    $pass = $txtPass.Text

    if (-not $pc -or -not $user -or -not $pass) {
        [System.Windows.Forms.MessageBox]::Show("Preencha computador, usuário e senha.")
        return
    }

    try {
        $statusLabel.Text = "Conectando a $pc..."
        $secpass = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($user, $secpass)
        $apps = Invoke-Command -ComputerName $pc -ScriptBlock {
            Get-WmiObject -Class Win32_Product | Select-Object Name
        } -Credential $cred -ErrorAction Stop

        foreach ($app in $apps) {
            if ($app.Name) {
                $listBox.Items.Add($app.Name)
            }
        }

        $statusLabel.Text = "Programas carregados."
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Erro ao conectar ao computador remoto.`n$_")
        $statusLabel.Text = "Erro ao buscar programas."
    }
})

# Evento: Desinstalar
$btnUninstall.Add_Click({
    $pc = $txtPC.Text
    $user = $txtUser.Text
    $pass = $txtPass.Text
    $prog = $listBox.SelectedItem

    if (-not $prog) {
        [System.Windows.Forms.MessageBox]::Show("Selecione um programa para desinstalar.")
        return
    }
    if (-not $user -or -not $pass) {
        [System.Windows.Forms.MessageBox]::Show("Preencha usuário e senha.")
        return
    }

    $resposta = [System.Windows.Forms.MessageBox]::Show("Deseja realmente desinstalar '$prog'?", "Confirmação", "YesNo")
    if ($resposta -ne "Yes") { return }

    $statusLabel.Text = "Desinstalando $prog..."

    try {
        $secpass = ConvertTo-SecureString $pass -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($user, $secpass)
        Invoke-Command -ComputerName $pc -ScriptBlock {
            param($progName)
            $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $progName }
            if ($app) {
                $app.Uninstall() | Out-Null
                return "$progName desinstalado com sucesso."
            } else {
                return "Programa não encontrado: $progName"
            }
        } -ArgumentList $prog -Credential $cred -ErrorAction Stop | ForEach-Object {
            $statusLabel.Text = $_
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Erro durante desinstalação.`n$_")
        $statusLabel.Text = "Erro ao desinstalar."
    }
})

# ...existing code...