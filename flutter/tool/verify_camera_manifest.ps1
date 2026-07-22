param(
    [switch]$RequireMerged,
    [string]$SourceManifestPath,
    [string[]]$MergedManifestPath
)

$flutterRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$appManifestPath = if ($SourceManifestPath) {
    (Resolve-Path -LiteralPath $SourceManifestPath).Path
} else {
    Join-Path $flutterRoot 'android/app/src/main/AndroidManifest.xml'
}

$androidNamespace = 'http://schemas.android.com/apk/res/android'
$toolsNamespace = 'http://schemas.android.com/tools'

function Read-Permissions([string]$path) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Manifest not found: $path"
    }
    [xml]$document = Get-Content -Raw -LiteralPath $path
    foreach ($node in $document.manifest.'uses-permission') {
        [pscustomobject]@{
            Name = $node.GetAttribute('name', $androidNamespace)
            ToolsNode = $node.GetAttribute('node', $toolsNamespace)
        }
    }
}

$sourcePermissions = @(Read-Permissions $appManifestPath)

foreach ($permission in @('CAMERA', 'INTERNET')) {
    $required = $sourcePermissions | Where-Object {
        $_.Name -eq "android.permission.$permission" -and $_.ToolsNode -ne 'remove'
    }
    if (-not $required) {
        throw "Required source permission is missing: $permission"
    }
}

foreach ($permission in @('RECORD_AUDIO', 'WRITE_EXTERNAL_STORAGE')) {
    $removeRule = $sourcePermissions | Where-Object {
        $_.Name -eq "android.permission.$permission" -and $_.ToolsNode -eq 'remove'
    }
    if (-not $removeRule) {
        throw "Missing tools:node=remove rule for $permission"
    }
    $positiveForbidden = $sourcePermissions | Where-Object {
        $_.Name -eq "android.permission.$permission" -and $_.ToolsNode -ne 'remove'
    }
    if ($positiveForbidden) {
        throw "Forbidden source permission remains: $permission"
    }
}

$mergedCandidates = if ($MergedManifestPath) {
    $MergedManifestPath | ForEach-Object { (Resolve-Path -LiteralPath $_).Path }
} else {
    @(
        (Join-Path $flutterRoot 'build/app/intermediates/merged_manifests/debug/processDebugMainManifest/AndroidManifest.xml'),
        (Join-Path $flutterRoot 'build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml'),
        (Join-Path $flutterRoot 'build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml')
    ) | Where-Object { Test-Path -LiteralPath $_ }
}

if ($RequireMerged -and $mergedCandidates.Count -eq 0) {
    throw 'No debug merged manifest found. Run flutter build apk --debug first.'
}

foreach ($mergedPath in $mergedCandidates) {
    $mergedPermissions = @(Read-Permissions $mergedPath)
    foreach ($permission in @('CAMERA', 'INTERNET')) {
        $required = $mergedPermissions | Where-Object {
            $_.Name -eq "android.permission.$permission"
        }
        if (-not $required) {
            throw "Required merged permission is missing: $permission ($mergedPath)"
        }
    }
    foreach ($permission in @('RECORD_AUDIO', 'WRITE_EXTERNAL_STORAGE')) {
        if ($mergedPermissions | Where-Object {
            $_.Name -eq "android.permission.$permission"
        }) {
            throw "Forbidden permission remains in merged manifest: $permission"
        }
    }
}

Write-Output 'Camera manifest permission boundary verified.'
