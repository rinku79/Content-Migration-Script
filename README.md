# Content-Migration-Script by page scraping

Blog Url: https://rinkusitecore.wordpress.com/2022/02/17/sitecore-powershell-content-migration-from-different-site-using-web-page-scraping-and-htmlagility/

# Scripts  used for migration
- ContentMigrationMain.ps1
- ContentMigrationHelper.ps1 (Saved as Content-Migration-Helper in my local, it can have any name but accordingly need to update in main script as we invoke it there)

# Steps to follow

 a. Create excel which contains pageurl to browse for page-scrapping in predefined format (Sno, Siteurl, Group) e.g. ![image](https://user-images.githubusercontent.com/63503137/160296009-8cb37d0e-a9d2-43e3-b4b9-5ba0610fcd6d.png). As i had to scan different sites so added a grouptype to each because each site has different html structure.
 
 b. Create Parent folder in CMS under which you want to create content item and accordingly update itemid in ContentMigrationMain.ps1.
 
 c. Execute ContentMigrationMain.ps1 and upload excel file containing details mentions in step-a
 
 d. Once script completes it will create required item in cms so we need to verify them.

# Script Details
   ### 1. ContentMigrationMain.ps1
   
   a. Provide templateid of content item to be created using this script into $templateid variable
   
   b. It creates global object $doc. It is HtmlAgilityPack.HtmlDocument object which will contain page data.
   
   c. $inputcsvFile will contain reference to media item which is uploaded under master:\media library\Files\Migration. It will help to track history of uploaded excel files in media library.
   
   d. $csv, it will contain csv data which is recently uploaded into media library
   
   e. For each url it calls ProcessUrlAndContent() method. ProcessUrlAndContent method will read url data, call specific function based on grouptype to read dom content and then saves the data in cms as a ew item.
   
   f. getSecurityContentAndProcess(), getSupportContentAndProcess(), getFinServeContentAndProcess() and getHRContentAndProcess() are functions to read data of a grouptype from page. Based on page structure it reads required data using xPath queries.
     

   ### 2. ContentMigrationHelper.ps1
     It contains different helper function to process data and create item. 
     ![image](https://user-images.githubusercontent.com/63503137/160297523-b4188f00-d22a-40f6-9e2e-d5a3d5988a5c.png)

