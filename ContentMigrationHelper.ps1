<#
 .Synopsis
  Helper functions used in migration.

 .Description
   Functions which will called by migration process to format,log,dealt with reading csv from media folder etc.
   For html functions it will use $doc variable, which should be defined in calling script.

#>
#--------------------------Function to remove unwanted character got in page scraping-------------------------------------
function removeUnwantedCharacters($text) {
   if ($text -ne $null -or $text -ne '') {
        $unwantedchar = @('Â', 'â€™')
        
        $unwantedchar | foreach {
            $text = $text.Replace($_, '')
        }
    } 

    return $text 
}



#--------------function to write output into log files------------------------------

function log {
<#
        .SYNOPSIS
            Writes message to powershell UI as well as sitecore SPE log.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$string
    )
    write-host $string 
    write-log $string
}

<#--------------------------get media item--------------------------------------#>
function getMediaCsv{
<#
        .SYNOPSIS
            Get csv file from media library and convert that into readable format.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$item
    )

    $media = Get-Item $item
    # get stream and save content to variable $content
    [System.IO.Stream]$body = $media.Fields["Blob"].GetBlobStream()
    try {
        $contents = New-Object byte[] $body.Length
        $body.Read($contents, 0, $body.Length) | Out-Null
    } 
    finally {
        $body.Close()    
    }

    # convert to dynamic object
    $mediacsv = [System.Text.Encoding]::Default.GetString($contents) | ConvertFrom-Csv -Delimiter ","
    $mediacsv
}

#--------create branch template item-----------------
function New-BranchTemplateItem
{
    <#
        .SYNOPSIS
            Create new Sitecore item based on template/branch ID. 
			Specify the NewItemID only if needs to create item with the specific ID.
    #>
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        $Name,
        [Parameter(Mandatory=$True)]
        [string]$TemplateID,
        [Parameter(Mandatory=$True)]
        $ParentItem,
        [string]$NewItemID = ""
    )
     
    $scTemplateID = New-Object -TypeName "Sitecore.Data.ID" -ArgumentList $TemplateID
    $newItem = $null
     
    if ($NewItemID -ne "") 
    {
        $scItemID = New-Object -TypeName "Sitecore.Data.ID" -ArgumentList $NewItemID
        $newItem = [Sitecore.Data.Managers.ItemManager]::AddFromTemplate($Name, $scTemplateID, $ParentItem, $scItemID)
    }
    else 
    {
        $newItem = [Sitecore.Data.Managers.ItemManager]::AddFromTemplate($Name, $scTemplateID, $ParentItem)
    }
     
    return $newItem
}

#------------------------------------------------

#--------------function to remove class/style attributes----------------
   
function removeClassAndStyleAttributes{
 <#
        .SYNOPSIS
            Removes any class or style attribue(class|lang|style|size|face|[ovwxp]) from content.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$content
    )
    if (![string]::IsNullOrWhiteSpace($content)) {
        $content=   $content -replace "<([^>]*)(?:class|lang|style|size|face|[ovwxp]:\w+)=(?:'[^']*'|""[^""]*""|[^\s>]+)([^>]*)>","<`$1`$2>"
        $content= $content -replace "<!--(.*?)-->"  ,'' # to remove html comment
    }
    return $content
}




#--start>>-------------functions to read html document ------------------------------------------
  
function getFirstNodeValue {
 <#
        .SYNOPSIS
            Get first node from doc based on xpath supplied.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$xpath
    )
    $value = ''
    if ($doc -ne $null -and $doc -ne '') {
        $htmlNodes = $doc.DocumentNode.SelectSingleNode($xpath);
        if ($htmlNodes -ne $null -and $htmlNodes -ne '') {
            $value = $htmlNodes.InnerHtml
        } #html node condition
        
    } #doc condition
    return $value.trim()
}


function MergeAllNodeValue {
<#
        .SYNOPSIS
            Get all nodes which suffice xpath and then merge them.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$xpath
    )
    $value = ''
    if ($doc -ne $null -and $doc -ne '') {
        $htmlNodes = $doc.DocumentNode.SelectNodes($xpath);
        $htmlNodes | foreach-object {
            $htmlNode=$_
            if ($htmlNode -ne $null -and $htmlNode -ne '') {
                    $value =$value + '<br/>' + $htmlNode.InnerHtml
            } #html node condition
        } #foreach
        
    } #doc condition
    return $value.trim()
}
	function getMetaTagValue{
	<#
        .SYNOPSIS
            Gets doc meta tag value from its Content attribute from xpath supplied.
    #>
  [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True)]
        [string]$xpath
    )

    $value = ''
    if ($doc -ne $null -and $doc -ne '') {
        $htmlNodes = $doc.DocumentNode.SelectSingleNode($xpath);
        if ($htmlNodes -ne $null -and $htmlNodes -ne '') {
            $value = $htmlNodes.GetAttributeValue("content", "")
        } #html node condition
        
    } #doc condition
    return $value.trim()
}
#--end>>-------------functions to read html document ------------------------------------------

