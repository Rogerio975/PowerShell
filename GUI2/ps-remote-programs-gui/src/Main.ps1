# Main.ps1

Add-Type -AssemblyName System.Windows.Forms

function Show-InputBox {
    param (
        [string]$message,
        [string]$title
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(300, 200)
    $form.StartPosition = "CenterScreen"

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $message
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $form.Controls.Add($label)

    $userBox = New-Object System.Windows.Forms.TextBox
    $userBox.Location = New-Object System.Drawing.Point(10, 50)
    $userBox.Width = 250
    $form.Controls.Add($userBox)

    $passBox = New-Object System.Windows.Forms.TextBox
    $passBox.Location = New-Object System.Drawing.Point(10, 80)
    $passBox.Width = 250
    $passBox.UseSystemPasswordChar = $true
    $form.Controls.Add($passBox)

    $submitButton = New-Object System.Windows.Forms.Button
    $submitButton.Text = "Submit"
    $submitButton.Location = New-Object System.Drawing.Point(10, 110)
    $submitButton.Add_Click({
        $form.Tag = @{
            User = $userBox.Text
            Password = $passBox.Text
        }
        $form.Close()
    })
    $form.Controls.Add($submitButton)

    $form.ShowDialog() | Out-Null
    return $form.Tag
}

$credentials = Show-InputBox -message "Enter your credentials" -title "Remote Programs Viewer"

if ($credentials) {
    $username = $credentials.User
    $password = $credentials.Password

    # Import the module to get installed programs
    Import-Module -Name ".\modules\Get-RemotePrograms.psm1"

    # Replace 'remoteComputerName' with the actual remote computer name
    $remoteComputerName = "remoteComputerName"
    $installedPrograms = Get-InstalledPrograms -ComputerName $remoteComputerName -Username $username -Password $password

    # Display the installed programs
    $programsForm = New-Object System.Windows.Forms.Form
    $programsForm.Text = "Installed Programs"
    $programsForm.Size = New-Object System.Drawing.Size(400, 300)
    $programsForm.StartPosition = "CenterScreen"

    $programsListBox = New-Object System.Windows.Forms.ListBox
    $programsListBox.Location = New-Object System.Drawing.Point(10, 10)
    $programsListBox.Size = New-Object System.Drawing.Size(360, 200)
    $programsListBox.Items.AddRange($installedPrograms)
    $programsForm.Controls.Add($programsListBox)

    $closeButton = New-Object System.Windows.Forms.Button
    $closeButton.Text = "Close"
    $closeButton.Location = New-Object System.Drawing.Point(10, 220)
    $closeButton.Add_Click({ $programsForm.Close() })
    $programsForm.Controls.Add($closeButton)

    $programsForm.ShowDialog() | Out-Null
} else {
    [System.Windows.Forms.MessageBox]::Show("No credentials provided.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
}