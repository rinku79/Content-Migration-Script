<#
    .NAME
        Content Migration
    .SYNOPSIS
        Read page data from site and then store as new item in sitecore.
    .DESCRIPTION
        It reads siteurl from excel and then divide them based on its group, after that retrieve data as per page structure and save in its respective folder. 
#>

Invoke-script 'ContentMigrationProjectFolderInScriptLibrary/Content-Migration-Helper'  -verbose
#--start>>-------------------FUnctions to retrieve data based on group and save them-----------------------------------------------------
function CreateContentItem($groupType) {

    switch ($groupType) {
        'fs' { $itemid = '{67C779CF-052B-44DB-9DBD-2F4D75749B9D}'; break; } 
        'hr' { $itemid = '{154BBF85-1EF3-4798-B2C5-8B7A65BC8AE8}'; break; }
        'sp' { $itemid = '{629C79D3-3E34-4427-BE5C-2B106BCDB070}'; break; } 
        'sc' { $itemid = '{FD654F68-0CE6-4677-900C-4277FF43F951}'; break; } 
    }
    $parentitem = get-item  $itemid
    
    if (![string]::IsNullOrWhiteSpace($pagetitle)) {
        $itemname = $pagetitle
    }
    else {
        $currentdate = Get-Date -Format "MM-dd-yyyy"
        $itemname = '_No Page Title-' + $currentdate
    }
    $itemname = [Sitecore.Data.Items.ItemUtil]::ProposeValidItemName($itemname)
    $newitem = New-BranchTemplateItem -Name $itemname -TemplateID $templateId -ParentItem $parentitem
    Unlock-Item -item $newitem -PassThru
    
    $finalcontent= removeClassAndStyleAttributes $RichText1 
    
    $newitem.Editing.BeginEdit()
        $newitem."pageTitle" = $pagetitle
        $newitem."browserTitle" = $browsertitle ; 
        $newitem."MetaDescription" = $description ;  
        $newitem."MetaKeywords" = $keywords;  
        $newitem."richText1" = $finalcontent;
        if (![string]::IsNullOrWhiteSpace($RichText2)) {
            $newitem."richText2" = removeClassAndStyleAttributes $RichText2 ;
        }
        $newitem."importUrl" = $url
    $newitem.Editing.EndEdit()
    log  "Created new item $($newitem.id) having name: $($itemname)"
}


function getSecurityContentAndProcess() {
    $browsertitle = getFirstNodeValue("//title");
    $keywords = getMetaTagValue("//meta[@name='keywords']");
    $description = getMetaTagValue("//meta[@name='description']");
    $pagetitle = getFirstNodeValue("//h1[@class='et_pb_module_header']|//div[@class='et_pb_text_inner']//h1");
    $textinner = MergeAllNodeValue("//div[@class='et_pb_text_inner']"); 
    $toggletext=MergeAllNodeValue("//div[contains(@class, 'et_pb_toggle')]")
    $RichText1 = $textinner +  $toggletext; 
    $noThumbInner=MergeAllNodeValue("//article[contains(@class, 'et_pb_no_thumb')]")
    $RichText1 = $RichText1 +  $noThumbInner; 
    $resource=MergeAllNodeValue("//div[contains(@class, 'et_pb_blurb_container')]")
    $RichText1 = $RichText1 +  $resource; 
    $RichText1 = removeUnwantedCharacters $RichText1
    CreateContentItem 'sc'
}
function getSupportContentAndProcess() {
    $browsertitle = getFirstNodeValue("//title");
    $keywords = getMetaTagValue("//meta[@name='keywords']");
    $description = getMetaTagValue("//meta[@name='description']");
    $pagetitle = getFirstNodeValue("//div[@class='et_pb_text_inner']//h2|//div[@class='et_pb_text_inner']//h3");
    $RichText1 = getFirstNodeValue("//article");
    $RichText1 = removeUnwantedCharacters $RichText1
    CreateContentItem 'sp'
}


function getFinServeContentAndProcess() {
    $browsertitle = getFirstNodeValue("//title");
    $keywords = getMetaTagValue("//meta[@name='keywords']");
    $description = getMetaTagValue("//meta[@name='description']");
    $pagetitle = getFirstNodeValue("//h1[@id='page-title']");
    $RichText1 = getFirstNodeValue("//article");
    $RichText1 = removeUnwantedCharacters $RichText1
    $RichText2=MergeAllNodeValue("//div[contains(@class, 'block-block')]")
    $RichText2 = removeUnwantedCharacters $RichText2
    CreateContentItem 'fs'
}

function getHRContentAndProcess() {
    $browsertitle = getMetaTagValue("//meta[@name='pagetitle']");
    $keywords = getMetaTagValue("//meta[@name='keywords']");
    $description = getMetaTagValue("//meta[@name='description']");
    $pagetitle = getFirstNodeValue("//div[@id='content']//h2|//div[@class='content']//h2|//div[@id='content']//h3");
    $RichText1 = getFirstNodeValue("//div[@id='content']");
    $RichText1 = removeUnwantedCharacters $RichText1
      $RichText2=getFirstNodeValue("//div[@id='sidebar']")
    $RichText2 = removeUnwantedCharacters $RichText2
    CreateContentItem 'hr'
}

#-End...>>-------------------FUnctions to retrieve data based on group and save them-----------------------------------------------------

#------function to validate url exist or not, then execute respective function--------------------
function ProcessUrlAndContent() {
    $return = $false;
    $result = Invoke-WebRequest -UseBasicParsing -Uri $url
    $html = $result.Content
    $HTTP_Status = $result.StatusCode
    if ($HTTP_Status -eq 200) {
         $doc.LoadHtml($html);
         switch ($groupType) {
                    'fs' { getFinServeContentAndProcess ; break; }
                    'hr' { getHRContentAndProcess ; break; }
                    'sc' {getSecurityContentAndProcess ; break;}
                    'sp' {getSupportContentAndProcess; break;}
                }
        $return = $true
    }
    else {
        log "Response: " $HTTP_Status
        $return = $false
    }
  
    return $return
}


$itempath = '';
$templateid = '{45BCCF82-CBE7-4E05-9EB1-67D9CAEC3715}' 
$doc = New-Object -TypeName HtmlAgilityPack.HtmlDocument
 
$inputcsvFile = Receive-File (get-item "master:\media library\Files\Migration") -Title "Sites to Migrate..." -Description "Upload file containing site url for scrapping. " -overwrite
if ($inputcsvFile -eq "cancel") {
    exit
}

if ($inputcsvFile.Extension -ne "csv") {
    log "Invalid file extension, file uploaded is not of csv type"   ;
    exit
}

$csv = getMediaCsv($inputcsvFile.ID);

$countInserted = 0;
$countSkipped = 0;


$bulk = New-Object "Sitecore.Data.BulkUpdateContext";
$StopWatch = New-Object -TypeName System.Diagnostics.Stopwatch

log "There are $($csv.Count) records in the CSV";

$StopWatch.Start();
foreach ($record in $csv) {
    try {
            
        $url = $record.siteurl
        $groupType = $record.group
        log "Processing url- $($url) having group type-$($groupType)";
        $browsertitle = '' ; $keywords = ''; $description = ''; $pagetitle = ''; $RichText1 = '' ; $RichText2 = ''

        if (![string]::IsNullOrWhiteSpace($url)) {
         
            if (ProcessUrlAndContent) {
                  $countInserted++            
            }
            else {
                $countSkipped++
                log "Url-$($url) not exist"
            }
                
        } #if-url have value
    } #try    
    catch {
        $countSkipped++
        log "Error: $($_.Exception.Message)"    
    }
} #for    
    
$StopWatch.Stop();
$bulk.Dispose();

log "countInserted: $($countInserted) countSkipped: $($countSkipped) elapsed: $($StopWatch.Elapsed.ToString())";

