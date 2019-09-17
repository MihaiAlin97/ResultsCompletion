Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationClient.dll')
[System.Reflection.Assembly]::LoadFrom('C:\Program Files\Reference Assemblies\Microsoft\Framework\v3.0\UIAutomationTypes.dll')

$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent

##AutoIt for clicking on elements->too hard with win32 :))
Import-Module $ScriptDirectory\AutoItX.psd1 

Function SelectDocument{
    ##for signals and .seq

    if($args[0].equals('-SeqResult')){
        $type='Microsoft Excel Worksheet (*.xlsx)|*.xlsx';
        $LastDirectory=Split-Path -Path ($global:SeqResultPaths -split "`r`n")[0] -Parent
        }
        
    elseif($args[0].equals('-DCL')){
        $type='Microsoft Excel Worksheet (*.xlsx)|*.xlsx';
        $LastDirectory=Split-Path -Path ($global:DCLPaths -split "`r`n")[0] -Parent
        }

    Add-Type -AssemblyName System.Windows.Forms
    #Write-Host $LastDirectory;
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{ ##open a windows file browser when 'Select #file' button is clicked
        RestoreDirectory=$false;
        InitialDirectory=$LastDirectory;
        Filter=$type;
    }

    ##Write-Host $type
    $null = $FileBrowser.ShowDialog()

    if($args[0].equals('-SeqResult')){
        ##if no file was selected in file dialog,return
        if([string]::IsNullOrEmpty($FileBrowser.FileName)){return}
        
        ##set file containing signals to what was selected in File dialog
        $global:SeqResult = $FileBrowser.FileName;
        
        ##check if last selected file's path is contained in the paths file(SignalsPaths.txt);if it is contained replace it with "" and add last selected file's path to the beggining of file
        
        if($global:SeqResultPaths -like ("*"+$FileBrowser.FileName+"`r`n*")){
            $CurrentPath=$FileBrowser.FileName
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:SeqResultPaths=$global:SeqResultPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append selected file path to what is contained in the paths file
        $global:SeqResultPaths=($FileBrowser.FileName+"`r`n"+$global:SeqResultPaths)
        
        #create a new paths file containing updated infos
        $global:SeqResultPaths|Out-File "$ScriptDirectory\Paths\SeqResultPaths.txt" -width 1000
        
        #Write-Host $global:SequencePaths
    }##check if 'Select #file' button is called to select a .seq file
    
    elseif($args[0].equals('-DCL')){
        ##if no file was selected in file dialog,return
        if([string]::IsNullOrEmpty($FileBrowser.FileName)){return}
        
        ##set file containing signals to what was selected in File dialog
        $global:DCL = $FileBrowser.FileName;
        
        ##check if last selected file's path is contained in the paths file(ExcelPaths.txt);if it is contained replace it with "" and add last selected file's path to the beggining of file
        
        if($global:DCLPaths -like ("*"+$FileBrowser.FileName+"`r`n*")){
            $CurrentPath=$FileBrowser.FileName
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:DCLPaths=$global:DCLPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append selected file path to what is contained in the paths file
        $global:DCLPaths=($FileBrowser.FileName+"`r`n"+$global:DCLPaths)
        
        #create a new paths file containing updated info
        $global:DCLPaths|Out-File "$ScriptDirectory\Paths\DCLPaths.txt" -width 1000
        #Write-Host $global:SignalsPaths
    }##check if 'Select #file' button is called to select a .DBC file


    


}

Function Search-Sheet ##get specific columns from an excel
{ Param([String]$file,[string]$file2)
#Write-Host $file
#Write-Host $file2
if([string]::IsNullOrEmpty($file)){return}
if([string]::IsNullOrEmpty($file2)){return}

$Excel1 = New-Object -ComObject Excel.Application
$Excel1.Visible = $False

$Workbook = $Excel1.Workbooks.Open($file)

$Sheet=$Workbook.Sheets.item(1)
#$CSVpath=("$ScriptDirectory/DOORSCSV"+[guid]::NewGuid())

$AllRange=$Sheet.UsedRange
$LastRow=$AllRange.SpecialCells(11).row

$Name=$Sheet.Cells.Find("Test Case Name",[Type]::Missing,[Type]::Missing,1)
$Result=$Sheet.Cells.Find("Test Case Results",[Type]::Missing,[Type]::Missing,1)
$Ticket=$Sheet.Cells.Find("JIRA ticket",[Type]::Missing,[Type]::Missing,1)
$Remark=$Sheet.Cells.Find("Remark",[Type]::Missing,[Type]::Missing,1)

$NameAddress=($Name.AddressLocal($false,$false)).Replace("$","")
$ResultAddress=($Result.AddressLocal($false,$false)).Replace("$","")
$TicketAddress=($Ticket.AddressLocal($false,$false)).Replace("$","")
$RemarkAddress=($Remark.AddressLocal($false,$false)).Replace("$","")


$NameRange=($NameAddress+":"+($NameAddress[0]+$LastRow))
$ResultRange=($ResultAddress+":"+($ResultAddress[0]+$LastRow))
$TicketRange=($TicketAddress+":"+($TicketAddress[0]+$LastRow))
$RemarkRange=($RemarkAddress+":"+($RemarkAddress[0]+$LastRow))


$FinalDocument=($NameRange+","+$ResultRange+","+$TicketRange+","+$RemarkRange)
#Write-Host $FinalDocument


$NameColumn=@(($Sheet.Range($NameRange)).Value2)
$ResultColumn=@(($Sheet.Range($ResultRange)).Value2)
$TicketColumn=@(($Sheet.Range($TicketRange)).Value2)
$RemarkColumn=@(($Sheet.Range($RemarkRange)).Value2)


$TestCases= @{}


for($i=1;$i -le $NameColumn.Count;$i=$i+1){

    if([string]::IsNullOrEmpty($NameColumn[$i]) -eq $false){
    
        $TicketColumn[$i]=($TicketColumn[$i] -replace "`n","")
        $TicketColumn[$i]=($TicketColumn[$i] -replace " ","")
    
        $Testcases[$NameColumn[$i]]=[System.Collections.ArrayList]@()
        $null=$Testcases[$NameColumn[$i]].Add($ResultColumn[$i])
        $null=$Testcases[$NameColumn[$i]].Add($TicketColumn[$i])
        $null=$Testcases[$NameColumn[$i]].Add($RemarkColumn[$i])
        #Write-Host $Testcases[$NameColumn[$i]]
        
    }
}


#Write-Host $Testcases.Count
#Write-Host $Testcases["GWSZ"]
#Write-Host $Testcases["System time"]




#$range| select Value2 | export-csv -NoType ("C:\Users\uia99339\Documents\Work\ResultsCompletion\FinalDocument"+[guid]::NewGuid()+".csv")


$Workbook.Close($false)
$Excel1.Quit()

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel1)

Remove-Variable -Name Excel1


$Excel2 = New-Object -ComObject Excel.Application
$Excel2.Visible = $False

$Workbook = $Excel2.Workbooks.Open($file2)
$Workbook.SaveAs("$ScriptDirectory\Backups\BACKUP"+[guid]::NewGuid()+".xlsx")

$Sheet=$Workbook.Sheets.item(2)

$Test=$Sheet.Cells.Find("Test",[Type]::Missing,[Type]::Missing,1)


$BeginningRow=$Test.Row
$BeginningColumn=$Test.Column
#Write-Host $BeginningRow $BeginningColumn
#Write-Host $Sheet.Cells.Item($BeginningRow,$BeginningColumn).Value2
#Write-Host $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2

$CellToCheck=$Sheet.Cells.Item($BeginningRow+1,$BeginningColumn).Value2


$OverallStatus=$true
$GBBS=[System.Collections.ArrayList]@()

    while([string]::IsNullOrEmpty($CellToCheck) -eq $false){
        
        
        
        
        if($Testcases.ContainsKey($CellToCheck) -eq $true){
        
        
        
        
        $Testcases[$CellToCheck][1]=($Testcases[$CellToCheck][1] -replace "`n","")
        $Testcases[$CellToCheck][2]=($Testcases[$CellToCheck][2] -replace "`n","")
        
        
        $null=$GBBS.Add($Testcases[$CellToCheck][1])
        
        #Write-Host "Contains space " ($Testcases[$CellToCheck][1] -match "`n")
        #Write-Host $CellToCheck $Testcases.ContainsKey($CellToCheck)
        #Write-Host "Name:" $Testcases[$CellToCheck][0] " Ticket: " $Testcases[$CellToCheck][1] "Remark:" $Testcases[$CellToCheck][2]
        Write-Host $CellToCheck -ForegroundColor Red, Blue

            if($Testcases[$CellToCheck][0] -eq "OK"){
            
                if($Testcases[$CellToCheck][2] -match "SW version"){
                
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                
                }
                
                else{
                
                    if([string]::IsNullOrEmpty($Testcases[$CellToCheck][1]) -eq $true){##if TICKET column is empty,put only REMARK column without : symbol
                        
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][2]
                    
                    }
                     
                    else{
                    
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][1]+": "+$Testcases[$CellToCheck][2]
                        
                        
                    
                    } 
                    
                }
                    
                   
            }
            
            if(($Testcases[$CellToCheck][0] -match "n+.*o+.*k+.*") -eq $true){
            
                if([string]::IsNullOrEmpty($Testcases[$CellToCheck][1])-eq $true){##if TICKET column is empty,put only REMARK column without : symbol
                    Write-Host "No GBB present: " $CellToCheck -ForegroundColor Red
                    $OverallStatus=$false
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][2]
                
                }
                
                else{
                    if([string]::IsNullOrEmpty($Testcases[$CellToCheck][2])-eq $true){
                        $OverallStatus=$false
                        Write-Host "No Remark present: " $CellToCheck -ForegroundColor Red
                    
                    }
                    
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][1]+": "+$Testcases[$CellToCheck][2]
                    
                    
                }
            
            }
            
            
            
            if(($Testcases[$CellToCheck][0] -match "n+.*a+") -eq $true -or ($Testcases[$CellToCheck][0] -match "(no*t*.*t+(ested)*)") -eq $true){
            
                if([string]::IsNullOrEmpty($Testcases[$CellToCheck][1])-eq $true){##if TICKET column is empty,put only REMARK column without : symbol
                
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][2]
            
                }
                
                else{
                
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Testcases[$CellToCheck][1]+": "+$Testcases[$CellToCheck][2]
                 
                
                }
            
            
            
            }
            if([string]::IsNullOrEmpty($Testcases[$CellToCheck][0])-eq $true){
                $OverallStatus=$false
                Write-Host "No Result present: " $CellToCheck -ForegroundColor Red
            }
        }
        
        else{#check if testcase not relevant for 2018 and 2021
        
            if(($Sheet.Cells.Item($BeginningRow,$BeginningColumn+4).Value2 -match "x") -eq $false  -and ($Sheet.Cells.Item($BeginningRow,$BeginningColumn+5).Value2 -match "x") -eq $false){
            
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2="Nicht relevant for SP2021 and SP2018"
            
            }
        
            
        
        }
        
        $BeginningRow=$BeginningRow+1
        $CellToCheck=$Sheet.Cells.Item($BeginningRow,$BeginningColumn).Value2
        
        
        

    }
$Workbook.Save()    
$Workbook.Close($false)
$Excel2.Quit()

if($OverallStatus -eq $true){
Write-Host "Overall Status: OK" -ForegroundColor Green
}

else {
Write-Host "Overall Status: NOK" -ForegroundColor Red
}


[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel2)

Remove-Variable -Name Excel2

Write-Host $TicketColumn
Write-Host "fsafsafsafsafsa"
Write-Host $GBBS


$GBBS=$GBBS|select -Unique

$TicketColumn=$TicketColumn|select -Unique

$GBBS = $GBBS | Where-Object { $_ –ne "0" }
$GBBS = $GBBS | Where-Object { $_ –ne 0 }
$GBBS = $GBBS | Where-Object { $_ –match "GBB-" }

$TicketColumn = $TicketColumn | Where-Object { $_ –ne "0" }
$TicketColumn = $TicketColumn | Where-Object { $_ –ne 0 }


$result = @{}
$result.Add("total",$TicketColumn)
$result.Add("dcl",$GBBS)

Write-Host "whole" $result.total -ForegroundColor Cyan
Write-Host "dcl" $result.dcl -ForegroundColor Yellow
return $result

}

function ConnectIExplorer() {
    param($HWND)

    $objShellApp = New-Object -ComObject Shell.Application 
    try {
      $EA = $ErrorActionPreference; $ErrorActionPreference = 'Stop'
      $objNewIE = $objShellApp.Windows() | ?{$_.HWND -eq $HWND}
      
    } catch {
      #it may happen, that the Shell.Application does not find the window in a timely-manner, therefore quick-sleep and try again
      Write-Host "Waiting for page to be loaded ..." 
      Start-Sleep -Milliseconds 500
      try {
        $objNewIE = $objShellApp.Windows() | ?{$_.HWND -eq $HWND}
        
      } catch {
        Write-Host "Could not retreive the -com Object InternetExplorer. Aborting." -ForegroundColor Red
        $objNewIE = $null
      }     
    } finally { 
      $ErrorActionPreference = $EA
      $objShellApp = $null
    }
    return $objNewIE
  } 

Function Init-Page{

    $global:ie = New-Object -com InternetExplorer.Application
    
    $global:HWND = $global:ie.HWND
    $global:ie.visible=$false

    $global:ie.Navigate("https://www.google.ro/")
    $global:ie.visible=$false
    $global:ie = ConnectIExplorer -HWND $global:HWND
    while($global:ie.busy -and $global:ie.ReadyState -ne 4) { start-sleep -s 0.01 }

    Write-Host "Init done"



}

Function Get-Page{

    param($URL)
     
    $global:ie.Navigate($URL)
    $global:ie.visible=$false
    $global:ie = ConnectIExplorer -HWND $global:HWND

    while($global:ie.busy -and $global:ie.ReadyState -ne 4) { start-sleep -s 0.01 }

    Write-Host "sleep done"

    $source=$global:ie.Document.body.parentElement.outerHTML

    return $source
}

Function Close-IE{
    
    $global:ie.quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($global:ie)

}


Function Get-Jira{

    param($GBBlist)

    add-type -Path $ScriptDirectory\HtmlAgilityPack.dll
    #http://jira-id.zone2.agileci.conti.de/browse/GBB-3408

    #"http://jira-id.zone2.agileci.conti.de/issues/?filter=39442&jql=project+%3D+GBB+AND+issuetype+%3D+%22Problem+Report+%28PR%29%22+AND+labels+%3D+DrivingRelease+ORDER+BY+created+DESC&startIndex=0"
    
    Init-Page

    $source=Get-Page -URL "http://jira-id.zone2.agileci.conti.de/issues/?filter=39442&jql=project%20%3D%20GBB%20AND%20issuetype%20%3D%20%22Problem%20Report%20(PR)%22%20AND%20labels%20%3D%20DrivingRelease%20ORDER%20BY%20created%20DESC"

    $web = New-Object HtmlAgilityPack.HtmlDocument
    $web.LoadHtml($source)

    #$source|Out-File -FilePath "C:\Users\uia99339\Documents\Work\ResultsCompletion\Pr.txt"

    $Number=$web.DocumentNode.SelectNodes("//div[@class='pagination-container aui-item']/div[@class='pagination']")
    $Number=[int]$Number[0].Attributes["data-displayable-total"].Value;

    Write-Host $Number

    $issues=[System.Collections.ArrayList]@()

    Write-Host "number is" $Number
    for($i=0;$i -le $Number;$i = $i+50){

        $source=Get-Page -URL ("http://jira-id.zone2.agileci.conti.de/issues/?filter=39442&jql=project+%3D+GBB+AND+issuetype+%3D+%22Problem+Report+%28PR%29%22+AND+labels+%3D+DrivingRelease+ORDER+BY+created+DESC&startIndex="+$i)


        $web.LoadHtml($source)

        $iss=$web.DocumentNode.SelectNodes("//span[@class='issue-link-key']")##GBBS

        
        for($j=0;$j -lt $iss.Count ;$j=$j+1)
        {
            $null=$issues.Add($iss[$j].InnerText)
        }
    }
    #"http://jira-id.zone2.agileci.conti.de/browse/GBB-3440"
    #"http://jira-id.zone2.agileci.conti.de/si/jira.issueviews:issue-word/GBB-3440/GBB-3440.doc"
    Write-Host "List of Jira GBBs" $issues -ForegroundColor Blue
    #$titles

    $Final=[System.Collections.ArrayList]@()

    for($i=0;$i -lt $GBBlist.Count;$i=$i+1){
        #Write-Host ($GBBlist[$i]+"|")
        #Write-Host ($issues.Contains($GBBlist[$i]))
        
        if($issues.Contains($GBBlist[$i]) -eq $true)
        {
            Write-Host $GBBlist[$i] " is a Jira DrivingRelease GBB "-ForegroundColor Green
            
            $source=Get-Page -URL ("http://jira-id.zone2.agileci.conti.de/browse/"+$GBBlist[$i])


            $web.LoadHtml($source)
            
            $status=$web.DocumentNode.SelectNodes("//span[@id='status-val' and @class='value']")##status
            $status=$status[0].InnerText
            
            $title=$web.DocumentNode.SelectNodes("//h1[@id='summary-val' and @class='editable-field inactive']")##title
            $title=$title[0].InnerText
            
            
            $null=$Final.Add(@($GBBlist[$i],$status,$title))
        }
        
        else 
        {
            Write-Host $GBBlist[$i] " is not a Jira DrivingRelease GBB" -ForegroundColor Red
        }

    }
    


    Close-IE

    return $Final


}





function ShowProgress{
    Param([string]$text)
    Add-Type -AssemblyName System.Drawing
    
    $DesktopHandle=Get-AU3WinHandle "dwm.exe"
    $Graphics=[System.Drawing.Graphics]::FromHwnd($DesktopHandle)
    
    $TaskbarColor=[System.Drawing.Color]::FromArgb(25,30,34)
    $GreenColor=[System.Drawing.Color]::FromArgb(0,255,0)
    
    $TaskbarPen=[System.Drawing.Pen]($TaskbarColor)
    $TaskbarPen.Width=1
    $GreenPen=[System.Drawing.Pen]($GreenColor)
    
    $TaskbarBrush = New-Object System.Drawing.SolidBrush($TaskbarColor)
    $GreenBrush = New-Object System.Drawing.SolidBrush($GreenColor)
    
    
    $Rectangle=New-Object System.Drawing.Rectangle(1160,1043,1000,40)
    $Point=New-Object System.Drawing.Point(1450,1062.5)
    
    $Font = New-Object System.Drawing.Font("Arial", 30, "Regular","Pixel")
    $Format = [System.Drawing.StringFormat]::GenericDefault
    $Format.Alignment = [System.Drawing.StringAlignment]::Center
    $Format.LineAlignment = [System.Drawing.StringAlignment]::Center

    $WordPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $WordPath.AddString($text,[System.Drawing.FontFamily]$Font.FontFamily,[int]$Font.Style,[int]$Font.Size,[System.Drawing.Point]$Point,[System.Drawing.StringFormat]$Format)

    $Graphics.DrawRectangle($TaskbarPen,$Rectangle)
    $Graphics.FillRectangle($TaskbarBrush,$Rectangle)

    $Graphics.DrawPath($GreenPen,$WordPath)
    $Graphics.FillPath($GreenBrush,$WordPath)
    
}



Function UpdatePathInfo{

##add excel paths to paths file->for edited file paths;not for selected from dialog files
        
        if($global:SeqResultPaths -like ("*"+$global:syncHash.ComboBox1.Text+"`r`n*")){
            $CurrentPath=$global:syncHash.ComboBox1.Text
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:SeqResultPaths=$global:SeqResultPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append edited file path to what is contained in the paths file
        $global:SeqResultPaths=($global:syncHash.ComboBox1.Text+"`r`n"+$global:SeqResultPaths)
        
        #create a new paths file containing updated info
        $global:SeqResultPaths|Out-File "$ScriptDirectory\Paths\SeqResultPaths.txt" -width 1000
        
        ##
        
        
        ##add sequence paths to paths file->for edited file paths;not for selected from dialog files
        
        if($global:SeqResultPaths -like ("*"+$global:syncHash.ComboBox2.Text+"`r`n*")){
            $CurrentPath=$global:syncHash.ComboBox2.Text
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:SeqResultPaths=$global:SeqResultPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append edited file path to what is contained in the paths file
        $global:SeqResultPaths=($global:syncHash.ComboBox2.Text+"`r`n"+$global:DCLPaths)
        
        #create a new paths file containing updated info
        $global:SeqResultPaths|Out-File "$ScriptDirectory\Paths\DCLPaths.txt" -width 1000
        


}




Function DisplayPopUpWindow{   
        $ButtonType = 0 ##OK
        $MessageIcon = 64 ##Information
        $Result=[System.Windows.Forms.MessageBox]::Show($args[0],$args[1],$ButtonType,$MessageIcon)
        $handle=Get-AU3WinHandle $args[1]
        Show-AU3WinActivate $handle
}


Function EnableWindow{
        $global:syncHash.Button1.Enabled=$true
        $global:syncHash.Button2.Enabled=$true
        $global:syncHash.Button3.Enabled=$true
        $global:syncHash.Button4.Enabled=$true
        $global:syncHash.ComboBox1.Enabled=$true
        $global:syncHash.ComboBox2.Enabled=$true
}


Function DisableWindow{
        $global:syncHash.Button1.Enabled=$false
        $global:syncHash.Button2.Enabled=$false
        $global:syncHash.Button3.Enabled=$false
        $global:syncHash.Button4.Enabled=$false
        $global:syncHash.ComboBox1.Enabled=$false
        $global:syncHash.ComboBox2.Enabled=$false
}

