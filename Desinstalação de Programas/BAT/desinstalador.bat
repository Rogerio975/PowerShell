@echo off

:: Solicita o nome ou IP do computador remoto
set /p remoteComputer=Digite o nome ou IP do computador remoto: 

:: Solicita o nome do programa a ser desinstalado
set /p programName=Digite o nome do programa a ser desinstalado: 

:: Caminho do PsExec
set "psexecPath=C:\PSTools\PsExec.exe"  :: Substitua pelo caminho do PsExec

:: Comando para localizar e desinstalar o programa no computador remoto
set "wmicCommand=wmic product where ""name='%programName%'"" call uninstall /nointeractive"

:: Executa o comando remoto usando PsExec
echo Iniciando desinstalação do programa "%programName%" no computador remoto "%remoteComputer%"...
%psexecPath% \\%remoteComputer% cmd /c %wmicCommand%

if %errorlevel% equ 0 (
    echo Comando enviado. Verifique se o programa foi desinstalado com sucesso.
) else (
    echo Erro ao tentar desinstalar o programa.
)
pause