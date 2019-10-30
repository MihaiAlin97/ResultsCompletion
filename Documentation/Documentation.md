# Traceability search #
#  #
##Contents: ##
### 1.What does this program do?###
### 2.How does it work? ###
### 3.Upload files ###
### 4.Search between two values ###
### 5.Search multiple intervals ###
### 6.Important notes ###
## 1.What does this program do? ##
### Fairly simple.The program searches an Excell sheet for two cell values,and remembers all the cells between those values.###

###Then it searches a Sequence file to see if the values from cells are present in test case.###
###If so,the Test Cases containing values from Excel file(Export from Doors) are checked inside the strategies pane. ###

## 2.How does it work? ##
### Start the program by clicking on 'SearchTraceability.bat' ###
### You provide as input an Excel file,a Sequence file and two (or more)values to search between them.After that.###
### Click on 'Find' button ###

## 3.Upload files ##
### Click on '...' button to select a file from your computer. ###

### In the first field,you shold put an Excel file and in the second an uTAS sequence ###

## 4.Search between two values ##
### Enter the values you want to match in .seq file(in order->meaning first value is positioned in a cell before the second value)###
### Click 'Find' ###

## 5.Search multiple intervals ##
### Click on 'Add' button.A new pair of text boxes should be visible. ###


###Enter desired values and click 'Find' button###

## 6.Important notes ##
### - You should copy the contents of ReqFinder on your machine,otherwise it may not work ###
### - All files should be contained in the same location ###
### - Keep in mind that the search is performed for the first sheet of an Excel document ###
### - You should not switch to another window after the autoclicking on 'Strategies' window was performed;otherwise the program won't select the TC's ###
### -The process might be slow for large intervals(e.g. 1000 cells);Just wait :))###