@echo off

:: Configurações
set "remoteComputer=NomeDoComputadorRemoto"  :: Substitua pelo nome ou IP do computador remoto
set "programName=NomeDoPrograma"            :: Substitua pelo nome do programa a ser desinstalado
set "psexecPath=C:\PSTools\PsExec.exe"      :: Substitua pelo caminho do PsExec

:: Comando para localizar e desinstalar o programa no computador remoto
set "wmicCommand=wmic product where ""name like '%%%programName%%%'" call uninstall /nointeractive"

:: Executa o comando remoto usando PsExec
echo Iniciando desinstalação do programa "%programName%" no computador remoto "%remoteComputer%"...
%psexecPath% \\%remoteComputer% cmd /c %wmicCommand%

if %errorlevel% equ 0 (
    echo Comando enviado. Verifique se o programa foi desinstalado com sucesso.
) else (
    echo Erro ao tentar desinstalar o programa.
)