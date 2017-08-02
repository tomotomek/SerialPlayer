function PlaySerial{

    $nasiel = $false
    while(-Not $nasiel){
        $SerialName = Read-Host "Write name of serial: "
        $kino = Get-ChildItem -Path D:\ -Filter "KINO"
        $path = $kino.GetDirectories("*$SerialName*")

        if( !$path ){
            Write-Host "Zvoleny serial neexistuje"
            $nasiel = $false;
        } 
        else {
            $nasiel = $true
        }
        if( $nasiel ){
            if( !$path.GetDirectories("*1*").GetFiles("*s01e01*") ){
                Write-Host "Nazov epizody musi obsahovat podretazec tvaru: s01e01"
                $nasiel = $false
            }
            else {
                $nasiel = $true
            }
        }
        
    }

    if( $path.GetFiles('viewed.txt').Count -eq 0 ){
    #zaciname pozerat serial
        New-Item -Path $path.FullName -Name "viewed.txt" -ItemType "file" -Value "s01e01"
        $nextSerie = "01"
        $nextEpisode = "01"
    }
    else{
        
        $all, $nextSerie, $nextEpisode = getEpisode $path

        $writeSerie, $writeEpisode = getEpisodeToWrite $path $nextSerie $nextEpisode
        
        if(!$writeEpisode){
            Write-Host "Chyba v subore, alebo bola pozrena posledna epizoda"
            return
        }

        $viewed = $path.GetFiles('viewed.txt').FullName

        Add-Content "$viewed" $("`ns" + $writeSerie + "e" + "$writeEpisode")

    }
    play $path $nextSerie $nextEpisode
}

function getEpisode($coreFile){

    $lastPlayed = Get-Content -Tail 1 $coreFile.GetFiles('viewed.txt').FullName
    if( !$lastPlayed ){
        Write-Host "Can`t get viewed.txt file."
        return
    }
    $lastPlayed -replace '[\W]',''

    if( !($lastPlayed -match 's[0-9]{2}e[0-9]{2}') ){
        Write-Host "Bat text in file viewed.txt"
        return
    }

    $lastEpisode = $lastPlayed.substring($lastPlayed.length - 2, 2)
    $lastSerie = $lastPlayed.substring(1, 2)

    $integer = [int]$lastEpisode + 1
    $newEpisode = $integer.ToString('00')

    $newSerie = $lastSerie

    if( $path.GetDirectories("*$lastSerie*").GetFiles("*e$newEpisode*").Count -eq 0){  
        #ideme na novu seriu
        $intNum = [int]$lastSerie + 1
        $newSerie = $intNum.ToString('00')
        $newEpisode = "01"

        if($path.GetDirectories("*$newSerie*").Count -eq 0){
            Write-Host "Serial je dopozerany..."
            #TODO: mozno zmazat cely viewed.txt
            return
        }
    }

    Write-Host $newSerie

    return "$newSerie", "$newEpisode"
}

function getEpisodeToWrite($coreFile, $ns, $ne){

    if( !$coreFile -Or !$ns -Or !$ne) { 
        Write-Host "zly vsutp"
        return 
    }
    $nextEpisode = $ne

    $moreEpisodes = $coreFile.GetDirectories("*$ns*").GetFiles("*e$ne-*")
    if( $moreEpisodes.Count -ne 0 ){
        [string]$str = $moreEpisodes
        $i = $str.IndexOf("-")
        $nextEpisode = $moreEpisodes.Name.Substring($i+1, 2)
    }
    return $ns, $nextEpisode
}

function play{
    $path = $args[0]
    $serie = $args[1]
    $episode = $args[2]

    Write-Host $path.GetDirectories("*$serie")

    $startPath = $path.GetDirectories("*$serie*").GetFiles("*e$episode*").FullName

    Start-Process -FilePath $startPath
}

PlaySerial