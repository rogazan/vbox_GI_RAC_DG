function modificar_path {
    $misPaths = $env:Path -split ";"
    if ($misPaths -notcontains $EVB) {
        $misPaths = $misPaths + $EVB | Where-Object { $_ }
        $env:Path = $misPaths -join ';'
    }
}

function leer_parametros ($fichero) {
    $porDefecto = ".\params.json"
    if (-not $fichero) {
        $param = $porDefecto
    } else {
        $param = $fichero
    }
    
    if ( -not (Test-path -path $param -PathType leaf)) {
        "El fichero de parámetros NO existe, saliendo" | Write-Host
        exit
    }

    try { 
        $json = (Get-Content $param) | ConvertFrom-Json
    }
    catch {
        "El Fichero de parámetros no es un JSON válido, saliendo" | Write-Host
        exit
    }
    [string[]]$variables = ($json | get-member -Name * -MemberType NoteProperty).Name
    foreach ($variable in $variables) {
        Set-Variable -name $variable -value ($json.$variable) -Force -scope global
    }
}

function loc ($locucion) {
    if ($locucion -ne "") {
        if ($ConVoz -eq "SI") {
            while (-not $evento.terminaVoz.Iscompleted) {Start-Sleep -milliseconds 50}
            $evento.terminaVoz = $evento.voz.SpeakAsync($locucion)
        }
    }
    $null = New-Event -SourceIdentifier Mievento -MessageData $locucion
}

function validacion ($ok, $mensaje) {
    if ($ok) {
        loc ("Finalizado")
        loc ("")
    } else {
        loc ($mensaje)
        $evento.finGestor()
        exit
    }
}

function CargarInfraestructura {
    loc "Cargando infraestructura"
    $SAN          = [SAN]::new("Mi_SAN")
    $Red          = [Red]::new("Mi_Red")
    $Dimagen      = [DiscoImagen]::new($IMGDISCO)
    $DGA          = [DiscoDVD]::new($GAISO)
    $seg          = [Seguridad]::new()
    $GI           = [GI]::new()
    $global:Infra = [Infra]::new("Mi_Infra", $Red, $SAN, $seg, `
                $Dimagen, $DGA, $GI)
    validacion $true ""
}

function GestorDeEventos {
    Get-Job | Stop-Job |
    Get-Job | Remove-Job
    $global:evento = [GestorEventos]::new("mi_gestor")
}


