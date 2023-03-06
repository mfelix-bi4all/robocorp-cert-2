*** Settings ***
Documentation       Order robots from RobotSpareBin Industries Inc. using a orders file
...                 For each ordered robot:
...                 * Save the HTML receipt as a PDF file
...                 * Take a screenshot of the ordered robot
...                 * Embed the screenshot of the ordered robot to the PDF file
...                 Create a ZIP archive of the receipt PDF files in the output diretory

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Desktop
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.RobotLogListener


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Download the orders file
    Mute Run On Failure    Assert that the robot was ordered
    Get and process the orders
    Create a ZIP archive of the receipt PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download the orders file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=True

Get and process the orders
    # Keyword deduces that orders.csv contains a header without using the corresponding argument
    ${orders}=    Read table from CSV    orders.csv
    FOR    ${order}    IN    @{orders}
        Close the modal window
        Fill the form    ${order}
        Preview the robot
        Submit the order
        Store the order receipt as a PDF file    ${order}
        Take a screenshot of the ordered robot    ${order}
        Embed the screenshot of the ordered robot to the PDF file    ${order}
        Order another robot
    END

Close the modal window
    Click Button    OK

Fill the form
    [Arguments]    ${order}
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    css:input[placeholder="Enter the part number for the legs"]    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button    preview

Submit the order
    Click Button    order
    Wait Until Keyword Succeeds    1 min    1 sec    Assert that the robot was ordered

Assert that the robot was ordered
    TRY
        Wait Until Page Contains Element    order-another    1 sec
    EXCEPT
        # If an error message appears, need to click Order button again
        Click Button    order
        Wait Until Page Contains Element    order-another    1 sec
    END

Order another robot
    Click Button    order-another

Store the order receipt as a PDF file
    [Arguments]    ${order}
    ${receipt_html}=    Get Element Attribute    receipt    outerHTML
    Html To Pdf
    ...    ${receipt_html}
    ...    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}[Order number].pdf

Take a screenshot of the ordered robot
    [Arguments]    ${order}
    Screenshot
    ...    robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${order}[Order number].png

Embed the screenshot of the ordered robot to the PDF file
    [Arguments]    ${order}
    Open Pdf    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}[Order number].pdf
    Add Watermark Image To Pdf
    ...    ${OUTPUT_DIR}${/}screenshots${/}screenshot_${order}[Order number].png
    ...    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}[Order number].pdf
    ...    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}[Order number].pdf
    Close Pdf    ${OUTPUT_DIR}${/}receipts${/}receipt_${order}[Order number].pdf

Create a ZIP archive of the receipt PDF files
    ${zip_archive}=    Set Variable    ${OUTPUT_DIR}${/}receipts.zip
    Archive Folder With Zip
    ...    ${OUTPUT_DIR}${/}receipts
    ...    ${zip_archive}
