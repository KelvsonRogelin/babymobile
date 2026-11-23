param(
  [ValidateSet('run', 'build-apk', 'install', 'devices')]
  [string]$Action = 'run',
  [string]$DeviceId = '',
  [switch]$Release
)

$ErrorActionPreference = 'Stop'

$projectPath = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$linkPath = Join-Path $env:LOCALAPPDATA 'Temp\babymodile_flutter_link'
$adbPath = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
$apkPath = Join-Path $projectPath 'build\app\outputs\flutter-apk\app-debug.apk'

if (Test-Path -LiteralPath $linkPath) {
  Remove-Item -LiteralPath $linkPath -Recurse -Force
}

New-Item -ItemType Junction -Path $linkPath -Target $projectPath | Out-Null

try {
  Push-Location -LiteralPath $linkPath

  $flutterArgs = @()
  if ($Release) {
    $flutterArgs += '--release'
  } else {
    $flutterArgs += '--debug'
  }

  switch ($Action) {
    'run' {
      $args = @('run')
      if ($DeviceId) {
        $args += @('-d', $DeviceId)
      }
      $args += $flutterArgs
      & flutter @args
      exit $LASTEXITCODE
    }
    'build-apk' {
      & flutter build apk @flutterArgs
      exit $LASTEXITCODE
    }
    'install' {
      if (-not (Test-Path -LiteralPath $apkPath)) {
        & flutter build apk @flutterArgs
        if ($LASTEXITCODE -ne 0) {
          exit $LASTEXITCODE
        }
      }

      if (-not (Test-Path -LiteralPath $adbPath)) {
        throw "Nao encontrei o adb em '$adbPath'."
      }

      $installArgs = @()
      if ($DeviceId) {
        $installArgs += @('-s', $DeviceId)
      }
      $installArgs += @('install', '-r', $apkPath)

      & $adbPath @installArgs
      exit $LASTEXITCODE
    }
    'devices' {
      & flutter devices
      exit $LASTEXITCODE
    }
  }
}
finally {
  Pop-Location -ErrorAction SilentlyContinue
}
