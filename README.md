# DriversBackup 🛠️

![GitHub release](https://img.shields.io/github/v/release/daniellopes22/DriversBackup?style=flat-square)
![License](https://img.shields.io/github/license/daniellopes22/DriversBackup?color=blue)

Script Batch para **backup e restauração de drivers** com autoatualização via GitHub.

## Funcionalidades ✨
- Backup de drivers em caminhos pré-definidos ou personalizados
- Restauração de drivers a partir de backups
- Menu interativo com validação de entrada
- Sistema de logs detalhado
- Elevação de administrador com reexecução segura
- Atualização automática com processo temporário de troca do `.bat`

## Como Usar 🚀
1. Baixe o script:
   ```powershell
   Invoke-WebRequest -Uri "https://raw.githubusercontent.com/daniellopes22/DriversBackup/main/DriversBackup.bat" -OutFile "DriversBackup.bat"
   ```
2. Execute o script:
   ```bat
   DriversBackup.bat
   ```

## Versão atual
- `1.6`

## Observação sobre atualização
- A verificação/atualização automática usa URLs públicas do GitHub (`raw.githubusercontent.com`).
- Se o repositório estiver privado, a atualização automática pode não baixar arquivos sem autenticação.

## 📜 Licença
Este projeto está licenciado sob a **GNU GPL 3.0**.  
[Leia o texto completo aqui](LICENSE).
