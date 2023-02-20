*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Excel.Files
Library           RPA.PDF
Library           RPA.Archive
Library           OperatingSystem
Library           String
Library           Collections
Library           RPA.Tables
Library           RPA.Robocorp.WorkItems

*** Variables ***

${pdf_folder}    ${CURDIR}${/}documents
${image_folder}    ${CURDIR}${/}images

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create directories
    Open the robot order website
    Fill the data from orders.csv

*** Keywords ***

Create directories
    Create Directory    ${pdf_folder} 
    Create Directory    ${image_folder} 

Download the Excel file
    Download    https://robotsparebinindustries.com/SalesData.xlsx    overwrite=True

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Fill the form
    [Arguments]    ${row}
    Select From List By Value    head    ${row}[Head]
    Sleep    2s
    Wait Until Element Is Enabled   body
    Select Radio Button    body    ${row}[Body]
    Input Text    //*[@class="form-control"]    ${row}[Legs]
    Input Text    address    ${row}[Address]    
    
Preview the robot
    Click Button    preview
    Wait Until Page Contains Element    id:robot-preview-image
    Sleep    2s
    
Submit the order
    Click Button    order
    Wait Until Page Contains Element    id:robot-preview
    Sleep    4s

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML 
    Sleep    3s
    Html To Pdf    ${receipt_html}    ${pdf_folder}${/}${order_number}.pdf
    RETURN    ${pdf_folder}${/}${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    css:#robot-preview-image    ${image_folder}${/}${order_number}.png
    RETURN    ${image_folder}${/}${order_number}.png
    
Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    Add Watermark Image To PDF
    ...             image_path=${screenshot}
    ...             source_path=${pdf}
    ...             output_path=${pdf}
    RETURN    ${pdf}

Go to order another robot
    Click Button    order-another
    Sleep    2s
    Click Button    OK    

Close and start Browser prior to another transaction
    Close Browser
    Open the robot order website
    Continue For Loop

Checking Receipt data processed or not 
    FOR  ${i}  IN RANGE  ${100}
        ${alert}=  Is Element Visible  //div[@class="alert alert-danger"]  
        Run Keyword If  '${alert}'=='True'  Click Button  //button[@id="order"] 
        Exit For Loop If  '${alert}'=='False'       
    END
    
    Run Keyword If  '${alert}'=='True'  Close and start Browser prior to another transaction 

Fill the data from orders.csv
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${row}    IN    @{orders}
        Fill the form    ${row}
        Wait Until Keyword Succeeds    1 sec    1 sec    Preview the robot
        Wait Until Keyword Succeeds    1 sec    1 sec    Submit the order
        Checking Receipt data processed or not 
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        ${embed_robot_pdf} =    Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Archive Folder With Zip  ${pdf_folder}     ${CURDIR}${/}pdf_archive.zip    recursive=True  include=*.pdf
        # Add To Archive    ${embed_robot_pdf}    ${CURDIR}${/}pdf_archive.zip    
        # Empty Directory    ${pdf_folder} 
        # Empty Directory    ${image_folder} 
        Go to order another robot
    END
    


    




