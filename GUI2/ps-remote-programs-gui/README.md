# ps-remote-programs-gui

Este projeto é um script PowerShell com uma interface gráfica (GUI) que permite exibir os programas instalados em um computador remoto no domínio EMBASANET. O projeto é dividido em dois arquivos principais: `Main.ps1` e `Get-RemotePrograms.psm1`.

## Estrutura do Projeto

```
ps-remote-programs-gui
├── src
│   ├── Main.ps1
│   └── modules
│       └── Get-RemotePrograms.psm1
├── README.md
```

## Descrição dos Arquivos

- **src/Main.ps1**: Este é o ponto de entrada do script. Ele configura a interface gráfica para coletar as credenciais do usuário e exibir os programas instalados em um computador remoto.

- **src/modules/Get-RemotePrograms.psm1**: Este módulo contém funções que permitem a conexão com o computador remoto e a recuperação da lista de programas instalados. A função principal é `Get-InstalledPrograms`, que utiliza as credenciais fornecidas para acessar o sistema remoto.

## Instruções de Execução

1. **Pré-requisitos**:
   - PowerShell deve estar instalado no seu sistema.
   - As permissões adequadas devem ser concedidas para executar scripts PowerShell.

2. **Executando o Script**:
   - Abra o PowerShell como administrador.
   - Navegue até o diretório do projeto.
   - Execute o script `Main.ps1` usando o comando:
     ```powershell
     .\src\Main.ps1
     ```

3. **Interface Gráfica**:
   - A interface solicitará que você insira suas credenciais (usuário e senha).
   - Após a autenticação, o script exibirá a lista de programas instalados no computador remoto.

## Contribuições

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues ou pull requests para melhorias e correções.

## Licença

Este projeto está licenciado sob a MIT License - consulte o arquivo LICENSE para mais detalhes.