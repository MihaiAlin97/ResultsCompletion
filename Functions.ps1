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
$Result=$Sheet.Cells.Find("Test Case Result",[Type]::Missing,[Type]::Missing,1)
$Ticket=$Sheet.Cells.Find("JIRA ticket",[Type]::Missing,[Type]::Missing,1)
$Remark=$Sheet.Cells.Find("Remarks",[Type]::Missing,[Type]::Missing,1)

$NameAddress=($Name.AddressLocal($false,$false)).Replace("$","")
$ResultAddress=($Result.AddressLocal($false,$false)).Replace("$","")
$TicketAddress=($Ticket.AddressLocal($false,$false)).Replace("$","")
$RemarkAddress=($Remark.AddressLocal($false,$false)).Replace("$","")

Write-Host "First Addresses : "
Write-Host "Name: " $NameAddress
Write-Host "Result: " $ResultAddress
Write-Host "Ticket: " $TicketAddress
Write-Host "Remark: " $RemarkAddress
$NameRange=(($NameAddress[0]+([int]([string]$NameAddress[1])+1))+":"+($NameAddress[0]+$LastRow))
$ResultRange=(($ResultAddress[0]+([int]([string]$ResultAddress[1])+1))+":"+($ResultAddress[0]+$LastRow))
$TicketRange=(($TicketAddress[0]+([int]([string]$TicketAddress[1])+1))+":"+($TicketAddress[0]+$LastRow))
$RemarkRange=(($RemarkAddress[0]+([int]([string]$RemarkAddress[1])+1))+":"+($RemarkAddress[0]+$LastRow))


$FinalDocument=($NameRange+","+$ResultRange+","+$TicketRange+","+$RemarkRange)
Write-Host $FinalDocument


$NameColumn=@(($Sheet.Range($NameRange)).Value2)
$ResultColumn=@(($Sheet.Range($ResultRange)).Value2)
$TicketColumn=@(($Sheet.Range($TicketRange)).Value2)
$RemarkColumn=@(($Sheet.Range($RemarkRange)).Value2)


$TestCases= @{}


Write-Host "First Values : "
Write-Host "Name: " $NameColumn[0]
Write-Host "Result: " $ResultColumn[0]
Write-Host "Ticket: " $TicketColumn[0]
Write-Host "Remark: " $RemarkColumn[0]

Write-Host "Last Values : "

for($i=0;$i -le $NameColumn.Count;$i=$i+1){

    if([string]::IsNullOrEmpty($NameColumn[$i]) -eq $false){
        $NOKsymbol=""
        ##structure
        #Tescases["NameOfTestcase"] - > ([string]Result,([string]Ticket1,[string]Remark1),([string]Ticket2,[string]Remark2),([string]Ticket2,[string]Remark2).....)
        ##for the testcases with the same name,the same structure is applied;if one NOK exists,Result will be NOK
        
        ##trim the Remark and Ticket columns
        ##then remove the "'n" between them if there are more than 1 gbbs or remarks
        $TicketColumn[$i]=([string]$TicketColumn[$i]).Trim()
        $TicketColumn[$i]=(($TicketColumn[$i]) -replace "`n","ThisIsTheSplitter")
        $TicketColumn[$i]=$TicketColumn[$i] -split "ThisIsTheSplitter"
        
        #Write-Host ($TicketColumn[$i])[0] -ForegroundColor Red
        
        
        $RemarkColumn[$i]=([string]$RemarkColumn[$i]).Trim()
        $RemarkColumn[$i]=(($RemarkColumn[$i]) -replace "`n","ThisIsTheSplitter")
        $RemarkColumn[$i]=$RemarkColumn[$i] -split "ThisIsTheSplitter"
        
        #Write-Host ($RemarkColumn[$i])[0] -ForegroundColor Red
        
        
        #if remark and issue columns have more than 2 values,we need to select the items that are indeed text,not newlines;->for more than 2 GBBS the Trim,replace and split will return an array containing also newlines
        if($TicketColumn[$i].Count -gt 1){
            $TicketColumn[$i]=$TicketColumn[$i]| Where-Object { $_ -gt 1 }
            $RemarkColumn[$i]=$RemarkColumn[$i]| Where-Object { $_ -gt 1 }
        }

        
        #Write-Host $NameColumn[$i]
        #Write-Host $TicketColumn[$i|][0] $TicketColumn[$i][1] "Count:"$TicketColumn[$i].Count 
        #Write-Host $RemarkColumn[$i][0] $RemarkColumn[$i][1] "Count:"$RemarkColumn[$i].Count 
        
        #this is for when you have many tescases with the same name in SSTS report
        if($Testcases.ContainsKey($NameColumn[$i]) -eq $true){
        
            #Write-Host "Testcase " $NameColumn[$i] "has multiple mappings" -ForegroundColor Blue
            #Write-Host "This was used before" $Testcases[$NameColumn[$i]][0] $Testcases[$NameColumn[$i]][1] -ForegroundColor Cyan
            
            ##check if result is NOK,change result 
            
            
            ##Result logic for multiple testcases
            if(($ResultColumn[$i] -match "Nicht relevant") -and ($Testcases[$NameColumn[$i]][0] -ne "NOK") -and ($Testcases[$NameColumn[$i]][0] -ne "OK") -and ([string]::IsNullOrEmpty($Testcases[$NameColumn[$i]][0]) -eq $false)){
            
                $Testcases[$NameColumn[$i]][0]="Nicht relevant"
            }
            
            if(($ResultColumn[$i] -match "^O.*K" ) -and ($Testcases[$NameColumn[$i]][0] -ne "NOK") -and ([string]::IsNullOrEmpty($Testcases[$NameColumn[$i]][0]) -eq $false)){
                
                $Testcases[$NameColumn[$i]][0]="OK"
            }
            
            if(($ResultColumn[$i] -match "n+.*o+.*k+.*" -eq $true) -and ([string]::IsNullOrEmpty($Testcases[$NameColumn[$i]][0]) -eq $false)){
 
                $Testcases[$NameColumn[$i]][0]="NOK"
            }
            
            if([string]::IsNullOrEmpty($ResultColumn[$i]) -eq $true){
                $Testcases[$NameColumn[$i]][0]=""
            }
            
            ##put symbol for knowing when to remove comments
            
            if($ResultColumn[$i] -match "^O.*K" -eq $true){
                $NOKsymbol=""
            }            
            if(($ResultColumn[$i] -match "n+.*a+") -eq $true -or ($ResultColumn[$i] -match "(no*t*.*t+(ested)*)") -eq $true){
                $NOKsymbol="NHT"
            }             
            if($ResultColumn[$i] -match "n+.*o+.*k+.*" -eq $true){
                $NOKsymbol="NOK"
            }
            ##here we merge the columns
            ##0 is reserved for result
            $cnt=1
            for($j=0;$j -lt $TicketColumn[$i].Count;$j=$j+1){
                #Write-Host "Inserter Crap here:" $TicketColumn[$i] ($TicketColumn[$i])[$j] $RemarkColumn[$i] ($RemarkColumn[$i])[$j] -ForegroundColor Cyan
                
                #Write-Host "Inserted Crap here:" ($TicketColumn[$i])[$j]  ($RemarkColumn[$i])[$j] -ForegroundColor Cyan
                #$Testcases[$NameColumn[$i]]+=@(($TicketColumn[$i])[$j],($RemarkColumn[$i])[$j])
                #Write-Host "Another crap :" ($Testcases[$NameColumn[$i]][$cnt])[0] ($Testcases[$NameColumn[$i]][$cnt])[0] -ForegroundColor Blue,Red
                #$cnt=$cnt+1
                #Write-Host "Hear mio crapo " $TicketColumn[$i][$j] " " $RemarkColumn[$i][$j] -ForegroundColor Cyan
                #Write-Host "Hear mio crapo " ($TicketColumn[$i][$j]-match "GBB")  " " ($RemarkColumn[$i][$j]-gt 1)  -ForegroundColor Cyan
                
                
                    #Write-Host ($RemarkColumn[$i][$j]+$NOKsymbol) -ForegroundColor Yellow
                    $Combine=[System.Collections.ArrayList]@()
                    $null=$Combine.Add(@($TicketColumn[$i][$j],($RemarkColumn[$i][$j]+$NOKsymbol)))
                    $Testcases[$NameColumn[$i]]+=@($Combine)
                
            }
            
        }
        
        ##this is 1:1 SSTS report:DCL
        else{
            $Testcases[$NameColumn[$i]]=[System.Collections.ArrayList]@()
            
            ##if ok ish,put OK
            if($ResultColumn[$i] -match "^O.*K" -eq $true){
                
                $null=$Testcases[$NameColumn[$i]].Add("OK")
                $NOKsymbol=""
            }
            
            if(($ResultColumn[$i] -match "n+.*a+") -eq $true -or ($ResultColumn[$i] -match "(no*t*.*t+(ested)*)") -eq $true){
            
                $null=$Testcases[$NameColumn[$i]].Add("Nicht relevant")
                $NOKsymbol="NHT"
            }
            
            
            if($ResultColumn[$i] -match "n+.*o+.*k+.*" -eq $true){
 
                $null=$Testcases[$NameColumn[$i]].Add("NOK")
                $NOKsymbol="NOK"
            }
            
            if([string]::IsNullOrEmpty($ResultColumn[$i]) -eq $true){
                $null=$Testcases[$NameColumn[$i]].Add("")
            }
            
            
            #Write-Host "Name: " $NameColumn[$i] " Result: "$ResultColumn[$i] " Symbol: "$NOKsymbol 
            #Write-Host "First:" (($ResultColumn[$i] -match "n+.*a+") -eq $true -or ($ResultColumn[$i] -match "(no*t*.*t+(ested)*)") -eq $true) " " ($ResultColumn[$i] -match "n+.*o+.*k+.*") " " ($ResultColumn[$i] -match "^O.*K") -ForegroundColor Cyan
            ##here we merge the columns
            ##0 is reserved for result
            #Write-Host "Hear mio crapo " $TicketColumn[$i][$j] " " $RemarkColumn[$i][$j] -ForegroundColor Cyan
            for($j=0;$j -lt $TicketColumn[$i].Count;$j=$j+1){
                
                #Write-Host ($RemarkColumn[$i][$j]+$NOKsymbol) -ForegroundColor Yellow
                $null=$Testcases[$NameColumn[$i]].Add(@($TicketColumn[$i][$j],($RemarkColumn[$i][$j]+$NOKsymbol)))
                
            
            }
        
        
      
        
        }
      
    #Write-Host "Count" $Testcases[$NameColumn[$i]].Count -ForegroundColor Yellow
    #Write-Host "Structure" $Testcases[$NameColumn[$i]] -ForegroundColor Green
    #Write-Host "Segmented ->Result"$Testcases[$NameColumn[$i]][0] "Issue:" ($Testcases[$NameColumn[$i]][1])[0] "Remark: " ($Testcases[$NameColumn[$i]][1])[1]
    
    #if($Testcases[$NameColumn[$i]].Count -gt 2){
        #Write-Host "SecondSegmented ->Result"$Testcases[$NameColumn[$i]][0] "Issue:" ($Testcases[$NameColumn[$i]][2])[0] "Remark: " ($Testcases[$NameColumn[$i]][2])[1] -ForegroundColor Green
    #}
    
    $Testcases[$NameColumn[$i]]=($Testcases[$NameColumn[$i]]|select -unique )
    
    
    #Write-Host "Segmented ->Result"$Testcases[$NameColumn[$i]][0] "Issues and Remarks" $Testcases[$NameColumn[$i]][1]
    }
}


#Write-Host $Testcases.Count
#Write-Host $Testcases["GWSZ"]
#Write-Host $Testcases["System time"]

#$Testcases[Name] -> 0 is the Result;then all elements are pairs :(Issue,Remark)


##remove comments from not relevant testcases,if the final result is OK or NOK
#foreach($key in $Testcases.Keys){



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
$Backup=$Workbook
$Name=("$ScriptDirectory\Backups\BACKUP"+[guid]::NewGuid()+".xlsx")
$Backup.SaveAs($Name)

$Sheet=$Workbook.Sheets.item(2)





$Test=$Sheet.Cells.Find("Test",[Type]::Missing,[Type]::Missing,1)
$BeginningRow=$Test.Row
$BeginningColumn=$Test.Column
$CellToCheck=$Sheet.Cells.Item($BeginningRow+1,$BeginningColumn).Value2


$OverallStatus=$true
$GBBS=[System.Collections.ArrayList]@()
$ACC=[System.Collections.ArrayList]@()

$ErrorList=@{}
$ErrorList["GBB"]=[System.Collections.ArrayList]@()
$ErrorList["Result"]=[System.Collections.ArrayList]@()
$ErrorList["Missing"]=[System.Collections.ArrayList]@()

Write-Host "Starting..." -ForegroundColor Blue
Write-Host `n

    while([string]::IsNullOrEmpty($CellToCheck) -eq $false){
        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=""
        
        
        if($Testcases.ContainsKey($CellToCheck) -eq $true){
        
            #Write-Host $Testcases[$CellToCheck].Count 
            Write-Host `n
            Write-Host "Testcase: "$CellToCheck  -ForegroundColor Blue,Red -NoNewline
            Write-Host " Result: " $Testcases[$CellToCheck][0] " " -ForegroundColor Blue -NoNewline
            Write-Host `n
            
            
            for($i=1;$i -lt $Testcases[$CellToCheck].Count ;$i=$i+1){
            
                #remove NOK and NHT for remark
                #$Remark = (($Testcases[$CellToCheck][$i])[1]).Replace("NHT","")
                #$Remark = $Remark.Replace("NOK","")

                Write-Host "    Issue: "($Testcases[$CellToCheck][$i])[0] " " -ForegroundColor Yellow -NoNewline
                
                Write-Host " Remark: "($Testcases[$CellToCheck][$i])[1] " "  -ForegroundColor Cyan -NoNewline
                Write-Host `n
                
                if($i -ge 2)##if there is only one ticket:remark pair,put "" between the cell's previous values and the pair,otherwise put newline
                {
                    $Symbol="`n"
                }
                else{
                    $Symbol=""
                }
                
                if((($Testcases[$CellToCheck][$i])[0] -match ".*(cond)*.*(accepted)+.*(by)*.*(BMW)*.*") -or (($Testcases[$CellToCheck][$i])[1] -match ".*(cond)+.*(accepted)+.*(by)*.*(BMW)*.*"))##put in ACC aray the accepted GBBS
                {
                    $null=$ACC.Add(($Testcases[$CellToCheck][$i])[0])
                    
                }
                if($Testcases[$CellToCheck][0] -eq "OK"){
                
                    if(($Testcases[$CellToCheck][$i])[1] -match "SW version"){
                    
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"          
                    }  
                    
                    ElseIf(($Testcases[$CellToCheck][$i])[1] -match "NHT"){
                            
                            if([string]::IsNullOrEmpty(($Testcases[$CellToCheck][$i])[0]) -eq $false){##if Result is OK and Remark is from a Nicht relevant testcase and GBB not missing,put Remark
                                $Testcases[$CellToCheck][$i][1]=(($Testcases[$CellToCheck][$i])[1]).Replace("NHT","")##remove NHT symbol
                                $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                                $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[0]+": "+($Testcases[$CellToCheck][$i])[1]
                            }          
                    } 
                                     
                    else
                    {   
                        if([string]::IsNullOrEmpty(($Testcases[$CellToCheck][$i])[0]) -eq $true){##if TICKET column is empty,put only REMARK column without : symbol   
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[1] 
                        }
                        
                        else{
                        
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="OK"
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[0]+": "+($Testcases[$CellToCheck][$i])[1]
                            
                            ##add valid issues to GBBS
                            $null=$GBBS.Add(($Testcases[$CellToCheck][$i])[0])
                        }
                    }
                }
                
                if($Testcases[$CellToCheck][0] -eq "NOK"){
                
                    if(($Testcases[$CellToCheck][$i])[1] -match "SW version"){
                    
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"          
                    }  
                    
                    ElseIf(($Testcases[$CellToCheck][$i])[1] -match "NHT"){
                            
                            if([string]::IsNullOrEmpty(($Testcases[$CellToCheck][$i])[0]) -eq $false){##if Result is OK and Remark is from a Nicht relevant testcase and GBB not missing,put Remark
                                $Testcases[$CellToCheck][$i][1]=(($Testcases[$CellToCheck][$i])[1]).Replace("NHT","")##remove NHT symbol
                                $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
                                $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[0]+": "+($Testcases[$CellToCheck][$i])[1]
                                
                                ##add valid issues to GBBS
                                $null=$GBBS.Add(($Testcases[$CellToCheck][$i])[0])
                            }          
                    } 
                    
                    else{
                    
                        if(([string]::IsNullOrEmpty(($Testcases[$CellToCheck][$i])[0]) -eq $true) -and (($Testcases[$CellToCheck][$i])[1] -match "NOK")){##if TICKET column is empty,put only REMARK column without : symbol
                            
                            $Testcases[$CellToCheck][$i][1]=(($Testcases[$CellToCheck][$i])[1]).Replace("NOK","")
                            
                            Write-Host "Error:No GBB present" -ForegroundColor Red                       
                            $null=$ErrorList["GBB"].Add(("Error:No GBB present in "+$CellToCheck))
                            
                            $OverallStatus=$false
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[1]
                        }
                        
                        else{
                            
                            $Testcases[$CellToCheck][$i][1]=(($Testcases[$CellToCheck][$i])[1]).Replace("NOK","")
                            
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="NOK"
                            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[0]+": "+($Testcases[$CellToCheck][$i])[1]
                            
                            ##add valid issues to GBBS
                            $null=$GBBS.Add(($Testcases[$CellToCheck][$i])[0])
                        
                        }
                    }
                }
                
                if($Testcases[$CellToCheck][0] -eq "Nicht relevant"){
                    ($Testcases[$CellToCheck][$i])[1]=(($Testcases[$CellToCheck][$i])[1]).Replace("NHT","")
                
                    if([string]::IsNullOrEmpty(($Testcases[$CellToCheck][$i])[0]) -eq $true){##if TICKET column is empty,put only REMARK column without : symbol

                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
                        $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[1]
                    }
                    
                    else{
                    
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
                    $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2=$Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2+$Symbol+($Testcases[$CellToCheck][$i])[0]+": "+($Testcases[$CellToCheck][$i])[1]
                    
                    ##add valid issues to GBBS
                    $null=$GBBS.Add(($Testcases[$CellToCheck][$i])[0])
                    
                    }         
                }
                
                
                if([string]::IsNullOrEmpty($Testcases[$CellToCheck][0])-eq $true){
                    $OverallStatus=$false
                    Write-Host "Error:No Result present "-ForegroundColor Red 
                    
                    $null=$ErrorList["Result"].Add(("Error:No Result present in "+$CellToCheck))
                    ##add valid issues to GBBS
                    $null=$GBBS.Add(($Testcases[$CellToCheck][$i])[0])
                }
                
            }
            
            
        }
        
        if(($Sheet.Cells.Item($BeginningRow,$BeginningColumn+4).Value2 -match "x") -eq $false  -and ($Sheet.Cells.Item($BeginningRow,$BeginningColumn+5).Value2 -match "x") -eq $false){
            
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2="Nicht relevant for SP2021 and SP2018"
            
        }
        
        if($Testcases.ContainsKey($CellToCheck) -eq $false){
        
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+1).Value2="Nicht relevant"
            $Sheet.Cells.Item($BeginningRow,$BeginningColumn+2).Value2="Not present in SSTS"
            
            Write-Host ("Warning:"+ $CellToCheck+" not found in SSTS ") -ForegroundColor DarkRed
            $null=$ErrorList["Missing"].Add(("Warning:"+$CellToCheck+" not found in SSTS ")) 
        
        }
        
        $BeginningRow=$BeginningRow+1
        $CellToCheck=$Sheet.Cells.Item($BeginningRow,$BeginningColumn).Value2
        
        
        

    }
    
$Workbook.Save()   

$Workbook.Close($false)
$Excel2.Quit()

$ErrorLogID=[guid]::NewGuid()


foreach($error in $ErrorList["GBB"]){Write-Host $error;$error|Out-File -FilePath ("$ScriptDirectory\Logs\Errors"+$ErrorLogID+".txt") -Append}
foreach($error in $ErrorList["Result"]){Write-Host $error;$error|Out-File -FilePath ("$ScriptDirectory\Logs\Errors"+$ErrorLogID+".txt") -Append}
foreach($error in $ErrorList["Missing"]){Write-Host $error;$error|Out-File -FilePath ("$ScriptDirectory\Logs\Errors"+$ErrorLogID+".txt") -Append}

if($OverallStatus -eq $true){
Write-Host "Overall Status: OK" -ForegroundColor Green
Write-Host "See $ScriptDirectory\Logs\ for the most recent overview of errors" -ForegroundColor Green
}

else {
Write-Host "Overall Status: NOK" -ForegroundColor Red
Write-Host "See $ScriptDirectory\Logs\ for the most recent overview of errors" -ForegroundColor Red
}





[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel2)

Remove-Variable -Name Excel2



$TicketColumn=$TicketColumn|select -Unique


$GBBS = $GBBS | Where-Object { $_ –match "GBB-" }

$TicketColumn = $TicketColumn | Where-Object { $_ –match "GBB-" }


for($i=0;$i -lt $ACC.Count;$i++){
    $match=[regex]::Match($ACC[$i],"GBB-[0-9]*")
    $ACC[$i]=$match.Value
    $ACC[$i]=$ACC[$i].Trim()
}

for($i=0;$i -lt $GBBS.Count;$i++){
    $GBBS[$i]=($GBBS[$i]).Trim()
}



$GBBS=$GBBS|select -Unique
$ACC=$ACC|select -Unique
$TicketColumn=$TicketColumn|select -Unique


$GBBS=Compare-Object -ReferenceObject $GBBS -DifferenceObject $ACC -PassThru

$result = @{}
$result.total=$TicketColumn
$result.DCLnormal=$GBBS
$result.DCLaccepted=$ACC
$result.ErrorLogID=$ErrorLogID
$result.DCLJiraTickets=$Name

return $result

}

function Login{

$cred=(Get-Credential).GetNetworkCredential()
(ConvertTo-SecureString $cred.Username -AsPlainText -Force)|ConvertFrom-SecureString|out-file "$ScriptDirectory\Resources\Secs1.txt"
(ConvertTo-SecureString $cred.Password -AsPlainText -Force)|ConvertFrom-SecureString|out-file "$ScriptDirectory\Resources\Secs2.txt"

}

function Get-LoginData{

$cred=@{}
$cred.Username=ConvertTo-SecureString -String (Get-Content "$ScriptDirectory\Resources\Secs1.txt")
$cred.Password=ConvertTo-SecureString -String (Get-Content "$ScriptDirectory\Resources\Secs2.txt")

$cred.Username=[System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($cred.Username))
$cred.Password=[System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($cred.Password))

return $cred
}

Function Download{
Param($URL,$Path)

    $cred=Get-LoginData
    $fin=($cred.Username+":"+$cred.Password)
    $fin
    $auth = 'Basic ' +[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fin))

    $req = New-Object System.Net.WebClient
    $req.Headers.Add('Authorization', $auth )

    $req.DownloadFile($URL,$Path)
}

function Export-GBBS{
param($GBBS,$Path)
    for($i=0;$i -lt $GBBS.Count;$i=$i+1){
        #($Path+"\"+$GBBS[$i]+".doc")
        $null=Download -URL ("http://jira-id.zone2.agileci.conti.de/si/jira.issueviews:issue-word/"+$GBBS[$i]+"/"+$GBBS[$i]+".doc") -Path ($Path+"\"+$GBBS[$i]+".doc")
    }


}

Function Get-Page{
    param($URL)
    $cred=Get-LoginData
    $fin=($cred.Username+":"+$cred.Password)
    $fin
    $auth = 'Basic ' +[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($fin))

    $req = New-Object System.Net.WebClient
    $req.Headers.Add('Authorization', $auth )

    $source=$req.DownloadString($URL)
    
    return $source
}

Function Get-Jira{

    param($GBBlist,$Path,$ErrorLogId)

    add-type -Path $ScriptDirectory\HtmlAgilityPack.dll
    #http://jira-id.zone2.agileci.conti.de/browse/GBB-3408

    #"http://jira-id.zone2.agileci.conti.de/issues/?filter=39442&jql=project+%3D+GBB+AND+issuetype+%3D+%22Problem+Report+%28PR%29%22+AND+labels+%3D+DrivingRelease+ORDER+BY+created+DESC&startIndex=0"
    
    

    $source=Get-Page -URL "http://jira-id.zone2.agileci.conti.de/issues/?jql=project%20%3D%20GBB%20AND%20issuetype%20%3D%20%22Problem%20Report%20(PR)%22%20AND%20labels%20%3D%20DrivingRelease%20ORDER%20BY%20created%20DESC"
    $web = New-Object HtmlAgilityPack.HtmlDocument
    $web.LoadHtml($source)

    

    #Write-Host $Number
    
    $Number=$web.DocumentNode.SelectNodes("//div[@class='navigator-content']")
    $Number=$Number[0].Attributes["data-issue-table-model-state"].Value;
    $Number=[int]([regex]::Match($Number,"(?<=(total&quot;:))(.*?)(?=(,&quot;))")).Value


    #Write-Host "number is" $Number
    
    $issues=@{}

    for($i=0;$i -le $Number;$i = $i+50){

        $source=Get-Page -URL ("http://jira-id.zone2.agileci.conti.de/issues/?jql=project%20%3D%20GBB%20AND%20issuetype%20%3D%20%22Problem%20Report%20(PR)%22%20AND%20labels%20%3D%20DrivingRelease%20ORDER%20BY%20created%20DESC&startIndex="+$i)

        $web.LoadHtml($source)
        
        $iss=$web.DocumentNode.SelectNodes("//tbody/tr[@class='issuerow']/td[@class='issuekey']/a[@class='issue-link' and position()=2]")##GBBS
        $tit=$web.DocumentNode.SelectNodes("//tbody/tr[@class='issuerow']/td[@class='summary']/p/a[@class='issue-link']")##
        $stat=$web.DocumentNode.SelectNodes("//tbody/tr[@class='issuerow']/td[@class='status']/span")

        for($j=0;$j -lt $iss.Count ;$j=$j+1)
        {
            #Write-Host $iss[$j].InnerText $tit[$j].InnerText $stat[$j].InnerText
            $key=[string]($iss[$j].InnerText)
            $issues.Add($key,@($tit[$j].InnerText,$stat[$j].InnerText))

        }
    }
    #Write-Host $issues.Keys
    #$issues.Keys|Out-FIle "C:\Users\uia99339\Documents\Work\ResultsCompletion\Resources\jira whole.txt"

    $Final=[System.Collections.ArrayList]@()
    $ErrorList=@{}
    $ErrorList["status"]=[System.Collections.ArrayList]@()
    $ErrorList["dcl"]=[System.Collections.ArrayList]@()
    
    for($i=0;$i -lt $GBBlist.Count;$i=$i+1){
        #Write-Host ($GBBlist[$i]+"|")
        #Write-Host ($issues.Contains($GBBlist[$i]))
        
        #Write-Host $issues.ContainsKey($GBBlist[$i]) $GBBlist[$i]
        if($issues.ContainsKey($GBBlist[$i]) -eq $true)
        {
            
            
            $issues[$GBBlist[$i]][1]=($issues[$GBBlist[$i]][1].Replace(" (ChM)","")).ToUpper()
            
            if(($issues[$GBBlist[$i]][1] -match "REALIZED") -eq $false -and ($issues[$GBBlist[$i]][1] -match "CLOSED" )-eq $false -and ($issues[$GBBlist[$i]][1] -match "DUPLICATE" )-eq $false){
                $null=$Final.Add(@($GBBlist[$i],$issues[$GBBlist[$i]][0],$issues[$GBBlist[$i]][1]))
                Write-Host $GBBlist[$i] " is a Jira DrivingRelease GBB "-ForegroundColor Green
                
            }
            
            else{
                Write-Host $GBBlist[$i] " has status" $issues[$GBBlist[$i]][1] -ForegroundColor Red
                $null=$ErrorList["status"].Add(("Warning:"+$GBBlist[$i]+" has status"+$issues[$GBBlist[$i]][1])) ##add it for logs
            }
            
            #Write-Host $GBBlist[$i] "  " $issues[$GBBlist[$i]][0] " " $issues[$GBBlist[$i]][1]
            #"http://jira-id.zone2.agileci.conti.de/si/jira.issueviews:issue-word/GBB-3440/GBB-3440.doc"
        }
        
        else 
        {
            
            Write-Host $GBBlist[$i] " is not a Jira DrivingRelease GBB" -ForegroundColor Red
            $null=$ErrorList["dcl"].Add(("Warning:"+$GBBlist[$i]+" is not a Jira DrivingRelease GBB")) ##add it for logs
        }

    }
    
    foreach($error in $ErrorList["status"]){Write-Host $error;$error|Out-File -FilePath ("$ScriptDirectory\Logs\Errors"+$ErrorLogID+".txt") -Append}
    foreach($error in $ErrorList["dcl"]){Write-Host $error;$error|Out-File -FilePath ("$ScriptDirectory\Logs\Errors"+$ErrorLogID+".txt") -Append}
    
    
    
    $exports=[System.Collections.ArrayList]@()
    
    foreach($gbb in $Final){
        $null=$exports.Add($gbb[0])
        
    }
    
    Export-GBBS -GBBS $exports -Path $Path

    
    return $Final


}

Function Complete-Jira{
param($GBBS,$index,$Path)

$Excel = New-Object -ComObject Excel.Application
$Excel.Visible = $False

$file="$ScriptDirectory\Resources\DCL_JIRA_Tickets.xlsx"
$Workbook = $Excel.Workbooks.Open($file)

$Sheet=$Workbook.Sheets.item(1)

$xlShiftDown = -4121


for($i=0;$i -lt $GBBS.Count;$i=$i+1){
    $xlShiftDown = -4121
    $eRow = $Sheet.cells.item($i+4,1).entireRow
    $active = $eRow.activate()
    $active = $eRow.insert($xlShiftDown)
    ##insert a new table row

    $Sheet.Cells.Item($i+2,1).Value2=($i+1)
    $Sheet.Cells.Item($i+2,2).Value2=($GBBS[$i])[0]
    $Sheet.Cells.Item($i+2,3).Value2=($GBBS[$i])[1]
    $Sheet.Cells.Item($i+2,4).Value2=($GBBS[$i])[2]
    if($i -ge $index){
        $Sheet.Cells.Item($i+1,5).Value2="Accepted by BMW"
    }
}

$Workbook.SaveAs("$ScriptDirectory\Resources\DCL_JIRA_Tickets"+[guid]::NewGuid()+".xlsx")   

$Workbook.Close($false)
$Excel.Quit()

[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Sheet)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)

Remove-Variable -Name Excel

}

Function Get-PathData{
#C:\Users\uia99339\Documents\Work\ResultsCompletion\Driving_Release_Checklist_3.11_SWIP_CLAR-High_A280_002_001_005.xlsx
Param($SSTS,$DCL)
$variant=""

$FeedbackPath="\\cw01\root\Loc\bbuv\did36231\32_QM_PV\09_Report\25_SW-Systemtest\00_Fahrfreigabe_&_HV_Freigabe\BMW Feedback\"
$TicketsPath= "\\cw01\root\Loc\bbuv\did36231\32_QM_PV\09_Report\25_SW-Systemtest\00_Fahrfreigabe_&_HV_Freigabe"

if($DCL -match "IC-Box"){$variant="IC-Box";$HW="IC-Box"}
if($DCL -match "CLAR-High"){$variant="CLAR-High";$HW="Clar-High"}

$variant=$variant+"_"

$A=([regex]::Match($DCL,"(?<=($variant))(.*?)(?=(_))")).Value
$SW=([regex]::Match($DCL,"(?<=($A))(.*?)(?=(.xlsx))")).Value


##get correct feedback path
if((Test-Path ($FeedbackPath+$A) )-eq $true){$FeedbackPath=($FeedbackPath+$A+"\DCL_JIRA_Tickets-"+(get-date).Day+(Get-Culture).DateTimeFormat.GetAbbreviatedMonthName((get-date).Month)+"_"+$HW+$SW+".xlsx")}
else {
New-Item -Path $FeedbackPath -Name $A -ItemType "directory"
$FeedbackPath=($FeedbackPath+$A+"\DCL_JIRA_Tickets-"+(get-date).Day+(Get-Culture).DateTimeFormat.GetAbbreviatedMonthName((get-date).Month)+"_"+$HW+$SW+".xlsx")
}

##get path to tickets

if($HW -eq "IC-Box"){$TicketsPath=$TicketsPath+"\IC_BOX\"}
if($HW -eq "Clar-High"){$TicketsPath=$TicketsPath+"\CLAR HIGH\"}

if((Test-Path ($TicketsPath+"SW"+$SW) )-eq $true)
{

$SW=($SW+" - "+(get-date).Day+(Get-Culture).DateTimeFormat.GetAbbreviatedMonthName((get-date).Month))
New-Item -Path $TicketsPath -Name ("SW"+$SW) -ItemType "directory"
$TicketsPath=$TicketsPath+"SW"+$SW

New-Item -Path ($TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\") -Name "OK_JIRA_tickets" -ItemType "directory"
New-Item -Path ($TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\") -Name "NOK_JIRA_tickets" -ItemType "directory"


$OKJiraTickets=$TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\OK_JIRA_tickets"
$NOKJiraTickets=$TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\NOK_JIRA_tickets"
}

else
{

New-Item -Path $TicketsPath -Name ("SW"+$SW) -ItemType "directory"
$TicketsPath=$TicketsPath+"SW"+$SW

New-Item -Path ($TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\") -Name "OK_JIRA_tickets" -ItemType "directory"
New-Item -Path ($TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\") -Name "NOK_JIRA_tickets" -ItemType "directory"

$OKJiraTickets=$TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\OK_JIRA_tickets"
$NOKJiraTickets=$TicketsPath+"\Fahrfreigabe_&_HV_Fahrfreigabe_JIRA_tickets\NOK_JIRA_tickets"
} 

return $HW,$SW,$A,$FeedbackPath,$OKJiraTickets,$NOKJiraTickets
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
        
        if($global:DCLPaths -like ("*"+$global:syncHash.ComboBox2.Text+"`r`n*")){
            $CurrentPath=$global:syncHash.ComboBox2.Text
            $CurrentPath=$CurrentPath -replace "\\","\\"
            $CurrentPath=$CurrentPath -replace "\.","\."
            $global:DCLPaths=$global:DCLPaths -replace ($CurrentPath+"`r`n"),""
            }
        
        ##append edited file path to what is contained in the paths file
        $global:DCLPaths=($global:syncHash.ComboBox2.Text+"`r`n"+$global:DCLPaths)
        
        #create a new paths file containing updated info
        $global:DCLPaths|Out-File "$ScriptDirectory\Paths\DCLPaths.txt" -width 1000
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

