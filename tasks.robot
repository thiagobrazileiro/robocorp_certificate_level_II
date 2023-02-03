*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Archive
Library             RPA.Dialogs
Library             RPA.Robocorp.Vault


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${orders_url}=    Get orders url from vault
    ${user_name}=    Ask for the user name
    Open the robot order website
    ${orders}=    Get orders    ${orders_url}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts


*** Keywords ***
Get orders url from vault
    ${secret}=    Get Secret    order_secrets
    ${orders_url}=    Set Variable    ${secret}[orders_url]
    RETURN    ${orders_url}

Ask for the user name
    Add heading    Define information
    Add text input    user_name    label=Hey there! What is your name?
    ${result}=    Run dialog
    RETURN    ${result.user_name}

Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${orders_url}
    Download    ${orders_url}    overwrite=True
    ${table}=    Read table from CSV    orders.CSV    header=True
    RETURN    ${table}

Close the annoying modal
    Click Button When Visible    class:btn-danger

Fill the form
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]

Preview the robot
    Click Button When Visible    id:preview

Submit the order
    ${receipt_exist}=    Is Element Visible    id:receipt
    WHILE    not ${receipt_exist}
        Click Button    id:order
        Sleep    1
        ${receipt_exist}=    Is Element Visible    id:receipt
    END

Store the receipt as a PDF file
    [Arguments]    ${order_number}
    ${order_receipt}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${order_receipt}    ${OUTPUT_DIR}${/}order_receipt_number${order_number}.pdf
    RETURN    ${OUTPUT_DIR}${/}order_receipt_number${order_number}.pdf

Take a screenshot of the robot
    [Arguments]    ${order_number}
    Screenshot    id:robot-preview-image    ${OUTPUT_DIR}${/}robot_preview_number${order_number}.png
    RETURN    ${OUTPUT_DIR}${/}robot_preview_number${order_number}.png

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    @{myfiles}=    Create List    ${screenshot}
    Open Pdf    ${pdf}
    Add Files To Pdf    ${myfiles}    ${pdf}    ${True}
    Close Pdf

Go to order another robot
    Click Button    id:order-another
    Wait Until Element Is Visible    class:modal-header

Create a Zip File of the Receipts
    Archive Folder With Zip    ${OUTPUT_DIR}    receipts.zip    recursive=True    include=*.pdf
