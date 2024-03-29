Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#allow execution of unsigned scripts

# include files
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    .("$ScriptDirectory\Functions.ps1")
}
catch {
    Write-Host "Error while loading supporting Program's functions" 
}
#Write-Host ("$ScriptDirectory\Functions.ps1")

#end include

Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
$SeqResult=''##Sequence test results
$DCL=''
$SeqResultPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\SeqResultPaths.txt")
$DCLPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\DCLPaths.txt")

$ExcelSearchResults=[System.Collections.ArrayList]@()##every result from Search-Sheet function is stored here

$syncHash = [hashtable]::Synchronized(@{})

#####
$syncHash.SeqResult=$SeqResult
$syncHash.DCL=$DCL
$syncHash.SeqResultPaths=$SeqResultPaths
$syncHash.DCLPaths=$DCLPaths
#####

$syncHash.SelectSeqResultButtonWasClicked=$false
$syncHash.SelectDCLButtonWasClicked=$false
$syncHash.CompleteResultsButtonWasClicked=$false
$syncHash.AddButtonWasClicked=$false



$syncHash.ScriptDirectory=$ScriptDirectory
$syncHash.Icon= New-Object System.Drawing.Icon("$ScriptDirectory\Excel.ico")
$syncHash.CompleteIcon= New-Object System.Drawing.Icon("$ScriptDirectory\Complete.jpeg")

$processRunspace =[runspacefactory]::CreateRunspace()
$processRunspace.ApartmentState = "STA"
$processRunspace.ThreadOptions = "ReuseThread"          
$processRunspace.Open()
##set available data for thread
$processRunspace.SessionStateProxy.SetVariable("syncHash",$syncHash)
    
##create powershell instance
##ui will run in another thread;when 'Generate Code' button will be clicked,it will set a variable outside the thread to true and it will start generating code
$ExecuteParallel= [PowerShell]::Create().AddScript({ 
    

    # include files
    $ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
    try {
        .("$syncHash.ScriptDirectory\Functions.ps1")
    }
    catch {
        Write-Host "Error while loading supporting PowerShell Scripts" 
    }
    Write-Host ("$syncHash.ScriptDirectory\Functions.ps1")


    Add-Type -assembly System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    [System.Windows.Forms.Application]::EnableVisualStyles()
    
    $syncHash.ReqFinder             = New-Object System.Windows.Forms.Form
    $syncHash.ReqFinder.Text        ='Result mapper'
    $syncHash.ReqFinder.Width       = 950
    $syncHash.ReqFinder.Height      = 300
    $syncHash.ReqFinder.MaximumSize = New-Object System.Drawing.Size(950, 900)
    $syncHash.ReqFinder.MinimumSize = New-Object System.Drawing.Size(950, 900)
    $syncHash.ReqFinder.Font         = 'Microsoft Sans Serif,10'
    $syncHash.ReqFinder.Icon         = $syncHash.Icon
    
    $syncHash.Label1                = New-Object System.Windows.Forms.Label
    $syncHash.Label1.Text           = "Start Req ID:"
    $syncHash.Label1.Location       = New-Object System.Drawing.Point(10,132)
    $syncHash.Label1.Font           = 'Microsoft Sans Serif,10'
 
    $syncHash.Label2                = New-Object System.Windows.Forms.Label
    $syncHash.Label2.Text           = "End Req ID:"
    $syncHash.Label2.Location       = New-Object System.Drawing.Point(210,132)
    $syncHash.Label2.Font           = 'Microsoft Sans Serif,10'
    

    $syncHash.ComboBox1             = New-Object System.Windows.Forms.ComboBox
    $syncHash.ComboBox1.Width       = 700
    $syncHash.ComboBox1.Location    = New-Object System.Drawing.Point(20,27)
    $syncHash.ComboBox1.Font        = 'Microsoft Sans Serif,8'
    $syncHash.ComboBox1.Items.AddRange([System.Collections.ArrayList]@($syncHash.SeqResultPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
    $syncHash.ComboBox1.SelectedItem=$syncHash.SeqResultPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)[0]    

    $syncHash.ComboBox2             = New-Object System.Windows.Forms.ComboBox
    $syncHash.ComboBox2.Width       = 700
    $syncHash.ComboBox2.Location    = New-Object System.Drawing.Point(20,87)
    $syncHash.ComboBox2.Font        = 'Microsoft Sans Serif,8'
    $syncHash.ComboBox2.Items.AddRange([System.Collections.ArrayList]@($syncHash.DCLPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
    $syncHash.ComboBox2.SelectedItem=$syncHash.DCLPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)[0]
    
    ##
    $syncHash.outputBox = New-Object System.Windows.Forms.TextBox 
    $syncHash.outputBox.Location = New-Object System.Drawing.Size(20,210) 
    $syncHash.outputBox.Size = New-Object System.Drawing.Size(900,900) 
    $syncHash.outputBox.MultiLine = $True 
    $syncHash.outputBox.ScrollBars = "Vertical" 

    ##button for selecting path to excel file
    $syncHash.Button1               = New-Object System.Windows.Forms.Button
    $syncHash.Button1.Location      = New-Object System.Drawing.Size(750,25)
    $syncHash.Button1.Size          = New-Object System.Drawing.Size(150,23)
    $syncHash.Button1.Text          = "Select SeqResult"
    $syncHash.Button1.Font          = 'Microsoft Sans Serif,10'

    ##button for selecting path to .seq file
    $syncHash.Button2               = New-Object System.Windows.Forms.Button
    $syncHash.Button2.Location      = New-Object System.Drawing.Size(750,85)
    $syncHash.Button2.Size          = New-Object System.Drawing.Size(150,23)
    $syncHash.Button2.Text          = "Select DCL"
    $syncHash.Button2.Font          = 'Microsoft Sans Serif,10'

    #calls Search-Sheet and Search-Sequence functions
    $syncHash.Button3               = New-Object System.Windows.Forms.Button
    $syncHash.Button3.Location      = New-Object System.Drawing.Size(450,130)
    $syncHash.Button3.Size          = New-Object System.Drawing.Size(125,23)
    $syncHash.Button3.Text          = "Complete results"
    $syncHash.Button3.Font          = 'Microsoft Sans Serif,10'
    #$syncHash.Button3.Icon          = $syncHash.CompleteIcon
    
    $syncHash.Button4               = New-Object System.Windows.Forms.Button
    $syncHash.Button4.Location      = New-Object System.Drawing.Size(575,130)
    $syncHash.Button4.Size          = New-Object System.Drawing.Size(200,23)
    $syncHash.Button4.Text          = "Generate feedback and exports"
    $syncHash.Button4.Font          = 'Microsoft Sans Serif,10'


    $syncHash.Button5               = New-Object System.Windows.Forms.Button
    $syncHash.Button5.Location      = New-Object System.Drawing.Size(20,170)
    $syncHash.Button5.Size          = New-Object System.Drawing.Size(125,40)
    $syncHash.Button5.Text          = "Log"
    $syncHash.Button5.Font          = 'Microsoft Sans Serif,10'
    
    $syncHash.Button6               = New-Object System.Windows.Forms.Button
    $syncHash.Button6.Location      = New-Object System.Drawing.Size(145,170)
    $syncHash.Button6.Size          = New-Object System.Drawing.Size(125,40)
    $syncHash.Button6.Text          = "Valid GBBs"
    $syncHash.Button6.Font   
    
    
    $syncHash.Button1.Add_Click({
        
        $syncHash.SelectSeqResultButtonWasClicked=$true
        
    })
        
    $syncHash.Button2.Add_Click({
    
        $syncHash.SelectDCLButtonWasClicked=$true
        
    })
    
    $syncHash.Button3.Add_Click({
        $syncHash.SeqResult=$syncHash.ComboBox1.Text;
        $syncHash.DCL=$syncHash.ComboBox2.Text;
        
        $syncHash.CompleteResultsButtonWasClicked=$true

    
    })
    $syncHash.Button4.Add_Click({
        
        
        
    })


    #$syncHash.ReqFinder.Controls.AddRange(@($syncHash.ComboBox1,$syncHash.ComboBox2,$syncHash.Button1,$syncHash.Button2,$syncHash.Button3,$syncHash.Button4,$syncHash.Button5,$syncHash.Button6,$syncHash.outputBox))
    $syncHash.ReqFinder.Controls.AddRange(@($syncHash.ComboBox1,$syncHash.ComboBox2,$syncHash.Button1,$syncHash.Button2,$syncHash.Button3))

    
    
    $syncHash.ReqFinder.ShowDialog()
    
    sleep -s 1
    
    
    

})


  
$ExecuteParallel.Runspace = $processRunspace
##start thread(used to display form in a non-freezing manner

$Handle = $ExecuteParallel.BeginInvoke()
#[System.Threading.Thread]::CurrentThread.GetApartmentState()

##execute main here
sleep -s 1

Register-ObjectEvent -InputObject $syncHash.ReqFinder -EventName FormClosed -Action {UpdatePathInfo;stop-process -Id $PID;}

cls

while($true){    

    
    if($syncHash.SelectSeqResultButtonWasClicked -eq $true){
        
    
        
        ##clear items from ComboBox
        $syncHash.ComboBox1.Items.Clear()
            
        ##call SelectDocument;Couldn't do this inside add_click because all variables used should be available inside the runspace add_click is present;not necesarry for variables that don't interact with variables bounded to thread
        SelectDocument -SeqResult;
        
        Write-Host $SeqResult
            
        ##copy text from authentic files to their equivalent in $syncHash in order to have the latest updated version in $syncHash
        $syncHash.SeqResultPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\SeqResultPaths.txt")
        $syncHash.SeqResult=$SeqResult
                        
        ##obtain the paths from file without empty lines   
        $syncHash.ComboBox1.Items.AddRange([System.Collections.ArrayList]@($syncHash.SeqResultPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
            
        ##put selected file inside combobox
        $syncHash.ComboBox1.SelectedItem=$syncHash.SeqResult;
    
    
        $syncHash.SelectSeqResultButtonWasClicked=$false  
    }
    
    if($syncHash.SelectDCLButtonWasClicked -eq $true){
        ##clear items from ComboBox
        $syncHash.ComboBox2.Items.Clear()
            
        ##call SelectDocument;Couldn't do this inside add_click because all variables used should be available inside the runspace add_click is present;not necesarry for variables that don't interact with variables binded to thread
        SelectDocument -DCL;
        
        Write-Host $DCL
            
        ##copy text from authentic files to their equivalent in $syncHash in order to have the latest updated version in $syncHash
        $syncHash.DCLPaths=[IO.File]::ReadAllText("$ScriptDirectory\Paths\DCLPaths.txt")
        $syncHash.DCL=$DCL
                        
        ##obtain the paths from file without empty lines   
        $syncHash.ComboBox2.Items.AddRange([System.Collections.ArrayList]@($syncHash.DCLPaths.Split("`r`n",[System.StringSplitOptions]::RemoveEmptyEntries)));
            
        ##put selected file inside combobox
        $syncHash.ComboBox2.SelectedItem=$syncHash.DCL;
    
    
        $syncHash.SelectDCLButtonWasClicked=$false 
    
    
    }
    
    if($syncHash.CompleteResultsButtonWasClicked -eq $true){
        DisableWindow  
        ##ensure files are correct
        ##check if both comboboxes have valid paths(ending in .seq and .DBC)
        #if(($syncHash.SeqResult -match "SSTS_GEN5CI_DCL_SW")-eq $false -and ($syncHash.DCL -match "Driving_Release_Checklist(.*\.xlsx)$")-eq $false){
        #    DisplayPopUpWindow "The paths you entered do not point to a valid Drivind Checklist SSTS report,nor to a valid Driving checklist release!" "Invalid Excel files"     
        #   $syncHash.CompleteResultsButtonWasClicked=$false
        #}
        
        #else{
                
        #    ##check if text provided inside combobox has extension .seq
        #    if(($syncHash.SeqResult -match "SSTS_GEN5CI_DCL_SW")-eq $false){
        #        DisplayPopUpWindow "The path you entered does not point to a valid Driving Checklist SSTS report!" "Invalid Driving Checklist SSTS report"     
        #        $syncHash.CompleteResultsButtonWasClicked=$false
        #    }
                    
        #    ##check if text provided inside combobox has extension .DBC
        #    if(($syncHash.DCL -match "Driving_Release_Checklist(.*\.xlsx)$")-eq $false){
        #        DisplayPopUpWindow "The path you entered does not point to a valid Driving Checklist Release!" "Invalid Driving Checklist Release"
        #        $syncHash.CompleteResultsButtonWasClicked=$false
        #    } 
        #    ##end
        #}
        
        
        if($syncHash.CompleteResultsButtonWasClicked -eq $true){
        
            #$ExcelSearchResults=[System.Collections.ArrayList]@()

            $stopwatch = New-Object System.Diagnostics.Stopwatch
            $stopwatch.Start()
            
            UpdatePathInfo
            
            Login
            
            $null,$null,$null,$null,$result =Search-Sheet -file $syncHash.ComboBox1.SelectedItem -file2 $syncHash.ComboBox2.SelectedItem
            
            #Write-Host "whole ret" $result.total -ForegroundColor Cyan
            #Write-Host "dcl ret" $result.dcl -ForegroundColor Yellow
            
            
            $null,$null,$NormalGBBS=Get-Jira -GBBlist $result.DCLnormal -ErrorLogId $result.ErrorLogID -Path "$ScriptDirectory\Resources"
            $null,$null,$AcceptedGBBS=Get-Jira -GBBlist $result.DCLaccepted -ErrorLogId $result.ErrorLogID -Path "$ScriptDirectory\Resources"
            $GBBS=$NormalGBBS+$AcceptedGBBS
            
            Complete-Jira  -GBBS $GBBS -index $NormalGBBS.Count
                        
            $stopwatch.Stop()
            
            Write-Host $stopwatch.Elapsed

            
            EnableWindow
        }
        EnableWindow
        
        $syncHash.CompleteResultsButtonWasClicked=$false
    }

}


$ExecuteParallel.EndInvoke($Handle)  
 
##close runspace
##it will happen only when x button is clicked
$processRunspace.Close()
$ExecuteParallel.Dispose()



