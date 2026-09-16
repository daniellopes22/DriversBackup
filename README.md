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

## Verificação técnica (2026-09-16)

### 1) Funcionalidade
- ✅ **Fluxo de menu e validação de entrada**: opções aceitam apenas `1-9`, com tratamento para entrada vazia/inválida.
- ✅ **Backup de drivers**: caminho é validado/criado antes da execução de `dism /online /export-driver`.
- ✅ **Restauração de drivers**: caminho é validado, arquivos `.inf` são iterados e instalados com `pnputil`, com contagem de sucesso.
- ✅ **Atualização automática**: versão remota é consultada, arquivo temporário é validado e substituição do `.bat` é feita por atualizador temporário com tentativas.
- ✅ **Elevação administrativa**: há tratamento para cancelamento/falha de elevação sem quebrar o fluxo.

### 2) Segurança
- ✅ **Sem segredos hardcoded** no script.
- ✅ **Download via HTTPS/TLS 1.2** para checagem de versão e atualização.
- ✅ **Logs de erro e fallback** em falhas de rede/download/elevação.
- ⚠️ **Risco residual**: atualização executa script remoto do `main` sem validação de assinatura/hash.

### 3) Compatibilidade
- ✅ Compatível com **Windows** (Batch + PowerShell + DISM + PnPUtil).
- ⚠️ Requer execução com privilégios de administrador para operações de backup/restauração.
- ⚠️ Em ambientes sem acesso ao `raw.githubusercontent.com`, a autoatualização pode falhar.
- ⚠️ A validação foi feita por **revisão estática** e histórico de execução do workflow; não houve teste interativo real de `cmd.exe` Windows neste ambiente Linux.

### 4) Evidências registradas
- Script analisado: `DriversBackup.bat` (fluxos de menu, backup, restauração, atualização, elevação).
- Documentação/versionamento: `README.md`, `version.txt`.
- Execuções recentes do workflow **Running Copilot cloud agent**:
  - Runs antigos cancelados:
    - `#1` — https://github.com/daniellopes22/DriversBackup/actions/runs/35119930002
    - `#2` — https://github.com/daniellopes22/DriversBackup/actions/runs/35120656579
  - Runs subsequentes com sucesso:
    - `#3` — https://github.com/daniellopes22/DriversBackup/actions/runs/35121297937
    - `#4` — https://github.com/daniellopes22/DriversBackup/actions/runs/35121482506
    - `#5` — https://github.com/daniellopes22/DriversBackup/actions/runs/35121562212
    - `#6` — https://github.com/daniellopes22/DriversBackup/actions/runs/35121652742

### 5) Recomendações
1. Adicionar verificação de integridade do arquivo atualizado (hash/assinatura).
2. Criar validação automatizada em runner Windows para testar fluxo real do Batch.
3. Opcional: publicar releases versionadas e atualizar o script a partir de artefato versionado em vez de `main`.

## Observação sobre atualização
- A verificação/atualização automática usa URLs públicas do GitHub (`raw.githubusercontent.com`).
- Se o repositório estiver privado, a atualização automática pode não baixar arquivos sem autenticação.

## 📜 Licença
Este projeto está licenciado sob a **GNU GPL 3.0**.  
[Leia o texto completo aqui](LICENSE).
