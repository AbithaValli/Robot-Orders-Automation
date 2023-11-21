*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${FALSE}
Library             RPA.HTTP
Library             RPA.Excel.Files
Library             RPA.PDF
Library             RPA.Tables
Library             RPA.Archive


*** Variables ***
${pdf_folder}               ${OUTPUT_DIR}${/}pdf_files
${screenshots_folder}       ${OUTPUT_DIR}${/}screenshot_files
${merged_folder}            ${OUTPUT_DIR}${/}merged_pdf_files
${zip_file}                 ${OUTPUT_DIR}${/}pdf_archive.zip


*** Tasks ***
Minimal task
    Open the Robot orders website
    Place Orders
    Create a ZIP file of receipt PDF files
    [Teardown]    close the browser


*** Keywords ***
Open the Robot orders website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Click Button    OK

Get Orders
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Place Orders
    ${orders}=    Read table from CSV    orders.csv    dialect=excel

    FOR    ${orders}    IN    @{orders}
        Place order for one robot    ${orders}
        Wait Until Keyword Succeeds    10x    1s    Take a screenshot of the robot    ${orders}
        Wait Until Keyword Succeeds    10x    1s    Store the receipt as a PDF file    ${orders}
        Wait And Click Button    id:order-another
        Click Button    OK
    END

Place order for one robot
    [Arguments]    ${orders}
    Select From List By Value    head    ${orders}[Head]
    Select Radio Button    body    ${orders}[Body]
    Input Text    //input[@placeholder='Enter the part number for the legs']    ${orders}[Legs]
    Input Text    address    ${orders}[Address]

Take a screenshot of the robot
    [Arguments]    ${orders}
    Wait And Click Button    id:preview
    Wait Until Page Contains Element    id:robot-preview-image
    Screenshot    id:robot-preview-image    ${screenshots_folder}${/}robot-preview-image-${orders}[Order number].png

Store the receipt as a PDF file
    [Arguments]    ${orders}
    Wait And Click Button    id:order
    Wait Until Page Contains Element    id:receipt
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${pdf_folder}${/}${orders}[Order number].pdf
    ${files}=    Create List
    ...    ${pdf_folder}${/}${orders}[Order number].pdf
    ...    ${screenshots_folder}${/}robot-preview-image-${orders}[Order number].png
    Add Files To Pdf    ${files}    ${merged_folder}${/}merged-doc-${orders}[Order number].pdf

Create a ZIP file of receipt PDF files
    ${zip_file_name}=    Set Variable    ${OUTPUT_DIR}/PDFs.zip
    Archive Folder With Zip
    ...    ${merged_folder}
    ...    ${zip_file_name}

close the browser
    Close Browser
