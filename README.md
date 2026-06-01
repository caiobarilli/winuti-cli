# winutil-cli

Fork do [WinUtil (Chris Titus Tech)](https://github.com/ChrisTitusTech/winutil) focado em uso via linha de comando — sem interface gráfica, sem dependências de WPF ou Electron. Tudo roda via PowerShell, local ou remotamente via SSH.

## O que foi removido

- Interface gráfica WPF inteira (`xaml/`, funções `WPF*`)
- Scripts de compilação e assinatura da GUI
- Temas, navegação de apps e outros configs exclusivos da interface
- Funções dependentes de `$sync` WPF

## O que foi mantido

- `config/` — JSONs de tweaks, apps, DNS, features e presets
- `functions/private/` — tweaks, instalação, serviços, registro e rede
- `functions/public/` — RemoveEdge
- `pester/configs.Tests.ps1` — testes de validação dos JSONs

## O que foi adicionado

- `winutil-cli.ps1` — entry point com menu interativo e suporte a parâmetros CLI
- `audit/audit.ps1` — auditoria completa do sistema em 8 blocos, salva logs em `C:\log\DD.MM.AAAA\`
- `tools/WinMemoryCleaner.exe` — baixado automaticamente na primeira execução

## Uso

> Requer PowerShell como Administrador.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\winutil-cli.ps1
```

### Menu interativo

```
winutil-cli
===========
[1] Audit       - Gerar log completo do sistema
[2] Tweaks      - Aplicar tweaks (Standard / Minimal / Advanced)
[3] Debloat     - Remover apps e APPX desnecessários
[4] DNS         - Trocar DNS
[5] Performance - Ativar/desativar Ultimate Performance
[6] Install     - Instalar apps via winget ou choco
[7] Memory      - Limpar memória RAM
[0] Sair
```

### Via parâmetro (CLI/SSH)

```powershell
.\winutil-cli.ps1 -Action audit
.\winutil-cli.ps1 -Action tweaks -Preset standard
.\winutil-cli.ps1 -Action tweaks -Preset minimal
.\winutil-cli.ps1 -Action tweaks -Preset advanced
.\winutil-cli.ps1 -Action debloat
.\winutil-cli.ps1 -Action dns -Provider cloudflare
.\winutil-cli.ps1 -Action dns -Provider google
.\winutil-cli.ps1 -Action dns -Provider quad9
.\winutil-cli.ps1 -Action performance
.\winutil-cli.ps1 -Action install -Apps "Git.Git,Microsoft.VSCode"
.\winutil-cli.ps1 -Action memory
```

## Audit

Gera os seguintes arquivos em `C:\log\DD.MM.AAAA\`:

- `01-sistema.txt` — hostname, uptime, versão do Windows
- `02-hardware.txt` — CPU, GPU, RAM, discos
- `03-processos.txt` — top 30 processos por consumo de RAM
- `04-servicos.txt` — serviços rodando
- `05-startup.txt` — programas na inicialização
- `06-rede.txt` — conexões ativas e portas abertas
- `07-tarefas.txt` — tarefas agendadas ativas
- `08-hyperv.txt` — estado das VMs Hyper-V

## Testes

```powershell
Import-Module Pester -MinimumVersion 5.0 -Force
Invoke-Pester .\pester\configs.Tests.ps1
```

## Roadmap

- [x] Entry point `winutil-cli.ps1` com menu CLI
- [x] Audit logs em `C:\log\DD.MM.AAAA\`
- [x] DNS via parâmetro
- [x] Ultimate Performance via `powercfg`
- [x] Limpeza de RAM via WinMemoryCleaner
- [ ] Lista de APPX para debloat
- [ ] Testes Pester para o entry point
- [ ] Suporte a `-Action tweaks` sem dependência de GUI

## Créditos

- [ChrisTitusTech/winutil](https://github.com/ChrisTitusTech/winutil) — projeto base
- [IgorMundstein/WinMemoryCleaner](https://github.com/IgorMundstein/WinMemoryCleaner) — limpeza de RAM