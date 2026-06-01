# winutil-cli

Fork do WinUtil sem GUI/WPF. Tudo via PowerShell CLI, local ou SSH.

- PowerShell 5.1 e 7+ compatível
- Sem dependências de WPF, Electron ou interface gráfica
- Encoding UTF-8 sem BOM, LF
- Mensagens de status: `[ OK ]`, `[ ERRO ]`, `[ AVISO ]`, `[ INFO ]`
- Variável global `$sync.configs` carrega os JSONs de config
- Funções em `functions/private/` e `functions/public/`
- Logs salvos em `C:\log\DD.MM.AAAA\`
- Comentários em português