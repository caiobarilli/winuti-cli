#Requires -Version 5.1
<#
.SYNOPSIS
    Testes Pester 5+ para winutil-cli.ps1
.DESCRIPTION
    Cobre sanidade, validacao de parametros e execucao com mock.
    Resultado salvo em C:\log\DD.MM.AAAA\pester-winutil-cli.txt
#>

BeforeAll {
    $Script:RootDir = Split-Path $PSScriptRoot -Parent
    $Script:LogDate = Get-Date -Format 'dd.MM.yyyy'
    $Script:LogDir  = "C:\log\$($Script:LogDate)"
    $Script:LogFile = "$($Script:LogDir)\pester-winutil-cli.txt"

    if (-not (Test-Path $Script:LogDir)) {
        New-Item -ItemType Directory -Path $Script:LogDir -Force | Out-Null
    }

    try { Start-Transcript -Path $Script:LogFile -Force | Out-Null } catch {}

    # Configura $sync global (necessario para as funcoes de acao)
    $global:sync = [hashtable]::Synchronized(@{})
    $global:sync.configs = @{}

    $configPath = Join-Path $Script:RootDir 'config'
    foreach ($name in 'dns', 'tweaks', 'preset', 'feature', 'applications') {
        $file = Join-Path $configPath "$name.json"
        if (Test-Path $file) {
            try { $global:sync.configs.$name = Get-Content $file -Raw | ConvertFrom-Json } catch {}
        }
    }

    # Carrega funcoes privadas/publicas (Set-WinUtilDNS, Remove-WinUtilAPPX, etc.)
    foreach ($subDir in @('functions\private', 'functions\public')) {
        $full = Join-Path $Script:RootDir $subDir
        if (Test-Path $full) {
            Get-ChildItem -Path $full -Filter '*.ps1' -File | ForEach-Object {
                try { . $_.FullName } catch {}
            }
        }
    }

    # Extrai e carrega as funcoes de acao de winutil-cli.ps1 via AST (sem executar o script)
    $scriptPath  = Join-Path $Script:RootDir 'winutil-cli.ps1'
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $scriptPath, [ref]$null, [ref]$parseErrors
    )
    $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true
    ) | ForEach-Object {
        Invoke-Expression $_.Extent.Text
    }

    # $root usado por Invoke-ActionAudit e outras funcoes de acao
    $global:root = $Script:RootDir
}

AfterAll {
    try { Stop-Transcript | Out-Null } catch {}
}

# ==============================================================
# SANIDADE
# ==============================================================
Describe "Sanidade" {

    It "winutil-cli.ps1 existe na raiz" {
        Test-Path (Join-Path $Script:RootDir 'winutil-cli.ps1') | Should -BeTrue
    }

    It "audit/audit.ps1 existe" {
        Test-Path (Join-Path $Script:RootDir 'audit\audit.ps1') | Should -BeTrue
    }

    Context "JSONs em config/" {
        It "<_>.json existe e e JSON valido" -ForEach @(
            'dns', 'tweaks', 'preset', 'feature', 'applications'
        ) {
            $file = Join-Path $Script:RootDir "config\$_.json"
            Test-Path $file | Should -BeTrue
            { Get-Content $file -Raw | ConvertFrom-Json } | Should -Not -Throw
        }
    }

    It "Funcoes em functions/ nao tem erros de sintaxe" {
        $invalidos = @()
        Get-ChildItem -Path (Join-Path $Script:RootDir 'functions') -Recurse -Filter '*.ps1' -File |
            ForEach-Object {
                $erros = $null
                [System.Management.Automation.Language.Parser]::ParseFile(
                    $_.FullName, [ref]$null, [ref]$erros
                ) | Out-Null
                if ($erros.Count -gt 0) { $invalidos += $_.Name }
            }
        $invalidos | Should -BeNullOrEmpty -Because "todos os .ps1 em functions/ devem ter sintaxe valida"
    }
}

# ==============================================================
# VALIDACAO DE PARAMETROS
# ==============================================================
Describe "Validacao de Parametros" {

    # 6>&1 redireciona o stream de Information (Write-Host PS 5+) para o pipeline
    It "-Action dns sem -Provider retorna [ ERRO ]" {
        $output = (Invoke-ActionDNS -Provider '') 6>&1 | Out-String
        $output | Should -Match '\[ ERRO \]'
    }

    It "-Action install sem -Apps retorna [ ERRO ]" {
        $output = (Invoke-ActionInstall -Apps '') 6>&1 | Out-String
        $output | Should -Match '\[ ERRO \]'
    }

    It "-Action dns -Provider custom sem -PrimaryDNS retorna [ ERRO ]" {
        $output = (Invoke-ActionDNS -Provider 'custom' -PrimaryDNS '') 6>&1 | Out-String
        $output | Should -Match '\[ ERRO \]'
    }
}

# ==============================================================
# EXECUCAO COM MOCK
# ==============================================================
Describe "Execucao com Mock" {

    Context "-Action audit" {
        It "gera os 8 arquivos de auditoria em C:\log\DD.MM.AAAA\" {
            Invoke-ActionAudit
            $logDir    = "C:\log\$(Get-Date -Format 'dd.MM.yyyy')"
            $esperados = @(
                '01-sistema.txt', '02-hardware.txt', '03-processos.txt',
                '04-servicos.txt', '05-startup.txt',  '06-rede.txt',
                '07-tarefas.txt',  '08-hyperv.txt'
            )
            foreach ($f in $esperados) {
                Test-Path (Join-Path $logDir $f) |
                    Should -BeTrue -Because "audit deve gerar o arquivo $f"
            }
        }
    }

    Context "-Action performance" {
        It "chama powercfg sem lancar excecao" {
            # Retorna lista simulada ja contendo o GUID original (Prioridade 1)
            Mock powercfg {
                "Power Scheme GUID: e9a42b02-d5df-448d-aa00-03f14749eb61  (Ultimate Performance)"
            }
            { Invoke-ActionPerformance -State 'on' } | Should -Not -Throw
        }
    }

    Context "-Action dns -Provider cloudflare" {
        It "chama Set-WinUtilDNS com o provider correto" {
            Mock Set-WinUtilDNS { }
            Invoke-ActionDNS -Provider 'cloudflare'
            Should -Invoke -CommandName Set-WinUtilDNS -Times 1 `
                -ParameterFilter { $DNSProvider -eq 'cloudflare' }
        }
    }
}
