Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Janela principal
$form = New-Object System.Windows.Forms.Form
$form.Text = "Desinstalar Programa Remotamente"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"

# Label e campo do nome do computador remoto
$labelPC = New-Object System.Windows.Forms.Label
$labelPC.Text = "Nome do computador remoto:"
$labelPC.Location = New-Object System.Drawing.Point(20, 20)
$labelPC.AutoSize = $true
$form.Controls.Add($labelPC)

$txtPC = New-Object System.Windows.Forms.TextBox
$txtPC.Location = New-Object System.Drawing.Point(200, 18)
$txtPC.Width = 300
$form.Controls.Add($txtPC)

# Botão para buscar programas
$btnBuscar = New-Object System.Windows.Forms.Button
$btnBuscar.Text = "Buscar Programas"
$btnBuscar.Location = New-Object System.Drawing.Point(200, 50)
$form.Controls.Add($btnBuscar)

# Lista de programas
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(20, 90)
$listBox.Size = New-Object System.Drawing.Size(540, 280)
$form.Controls.Add($listBox)

# Botão para desinstalar
$btnUninstall = New-Object System.Windows.Forms.Button
$btnUninstall.Text = "Desinstalar Selecionado"
$btnUninstall.Location = New-Object System.Drawing.Point(200, 390)
$form.Controls.Add($btnUninstall)

# Status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = ""
$statusLabel.Location = New-Object System.Drawing.Point(20, 430)
$statusLabel.Size = New-Object System.Drawing.Size(540, 30)
$form.Controls.Add($statusLabel)

# Evento: Buscar programas
$btnBuscar.Add_Click({
    $listBox.Items.Clear()
    $pc = $txtPC.Text
    if (-not $pc) {
        [System.Windows.Forms.MessageBox]::Show("Digite o nome do computador remoto.")
        return
    }

    try {
        $statusLabel.Text = "Conectando a $pc..."
        $apps = Invoke-Command -ComputerName $pc -ScriptBlock {
            Get-WmiObject -Class Win32_Product | Select-Object Name
        } -ErrorAction Stop

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
    $prog = $listBox.SelectedItem

    if (-not $prog) {
        [System.Windows.Forms.MessageBox]::Show("Selecione um programa para desinstalar.")
        return
    }

    $resposta = [System.Windows.Forms.MessageBox]::Show("Deseja realmente desinstalar '$prog'?", "Confirmação", "YesNo")
    if ($resposta -ne "Yes") { return }

    $statusLabel.Text = "Desinstalando $prog..."

    try {
        Invoke-Command -ComputerName $pc -ScriptBlock {
            param($progName)
            $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -eq $progName }
            if ($app) {
                $app.Uninstall() | Out-Null
                return "$progName desinstalado com sucesso."
            } else {
                return "Programa não encontrado: $progName"
            }
        } -ArgumentList $prog -ErrorAction Stop | ForEach-Object {
            $statusLabel.Text = $_
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Erro durante desinstalação.`n$_")
        $statusLabel.Text = "Erro ao desinstalar."
    }
})

# Exibe o formulário
[void]$form.ShowDialog()