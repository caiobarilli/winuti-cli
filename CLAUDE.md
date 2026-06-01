# winutil-cli

Fork do WinUtil (ChrisTitusTech) sem interface gráfica.

## Stack
- PowerShell 5.1 / 7+
- Sem WPF, sem Electron
- UTF-8 sem BOM, LF

## Estrutura
- `winutil-cli.ps1` — entry point CLI
- `audit/audit.ps1` — auditoria do sistema
- `functions/private/` e `functions/public/` — módulos
- `config/*.json` — tweaks, dns, preset, feature, applications

## Regras
- Sem dependência de `$sync` com objetos WPF
- Comentários em português
- Status: `[ OK ]`, `[ ERRO ]`, `[ AVISO ]`, `[ INFO ]`
- Logs em `C:\log\DD.MM.AAAA\`