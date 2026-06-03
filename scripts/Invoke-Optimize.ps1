function Invoke-Optimize {
    param(
        [string]$Preset,
        [string]$Kill
    )

    $sshProcesses = @(
        'LogonUI', 'SearchHost', 'StartMenuExperienceHost',
        'ShellExperienceHost', 'ShellHost', 'TextInputHost',
        'msedgewebview2', 'OfficeClickToRun'
    )

    # Service-backed processes: stopping the service keeps them down for the session.
    # Entries absent from this map fall back to Stop-Process.
    $serviceMap = @{
        'SearchHost'       = 'WSearch'
        'TextInputHost'    = 'TextInputManagementService'
        'OfficeClickToRun' = 'ClickToRunSvc'
    }

    $targets = [System.Collections.Generic.List[string]]::new()

    if ($Preset) {
        switch ($Preset.ToLower()) {
            'ssh' {
                Write-Status INFO "Preset 'ssh': stopping headless-incompatible processes..."
                foreach ($p in $sshProcesses) { $targets.Add($p) }
            }
            default {
                Write-Status ERROR "Unknown preset '$Preset'. Valid presets: ssh"
                return
            }
        }
    }

    if ($Kill) {
        $custom = $Kill -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
        if ($custom.Count -gt 0) {
            Write-Status INFO "Custom kill list: $($custom -join ', ')"
            foreach ($p in $custom) { $targets.Add($p) }
        }
    }

    if ($targets.Count -eq 0) {
        Write-Status ERROR "No processes specified. Use -Preset ssh and/or -Kill 'proc1,proc2'."
        return
    }

    $unique = $targets | Select-Object -Unique

    foreach ($proc in $unique) {
        $svcName = $serviceMap[$proc]

        if ($svcName) {
            $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
            if ($svc -and $svc.Status -eq 'Running') {
                Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
                Write-Status OK "Stopped: $proc"
            } else {
                Write-Status WARNING "Not running: $proc"
            }
        } else {
            $running = Get-Process -Name $proc -ErrorAction SilentlyContinue
            if ($running) {
                Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
                Write-Status OK "Stopped: $proc"
            } else {
                Write-Status WARNING "Not running: $proc"
            }
        }
    }

    Write-Status OK "Optimize complete."
}
