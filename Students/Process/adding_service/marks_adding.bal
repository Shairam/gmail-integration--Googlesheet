import ballerina/sql;
import ballerina/mysql;
import ballerina/log;
import ballerina/http;
import ballerina/config;
import wso2/gmail;

documentation{A valid access token with gmail and google sheets access.}
string accessToken = config:getAsString("ACCESS_TOKEN");

documentation{The client ID for your application.}
string clientId = config:getAsString("CLIENT_ID");

documentation{The client secret for your application.}
string clientSecret = config:getAsString("CLIENT_SECRET");

documentation{A valid refreshToken with gmail and google sheets access.}
string refreshToken = config:getAsString("REFRESH_TOKEN");

documentation{Sender email address.}
string senderEmail = config:getAsString("SENDER");

documentation{The user's email address.}
string userId = config:getAsString("USER_ID");

documentation{
    Google Sheets client endpoint declaration with http client configurations.
}

// student model
type Student{
    string name;
    int marks;
    int studentId;
    string email;
};

// Create SQL endpoint to MySQL database
endpoint mysql:Client employeeDB {
    host: config:getAsString("DATABASE_HOST", default = "localhost"),
    port: config:getAsInt("DATABASE_PORT", default = 3306),
    name: config:getAsString("DATABASE_NAME", default = "EMPLOYEE_RECORDS"),
    username: config:getAsString("DATABASE_USERNAME", default = "root"),
    password: config:getAsString("DATABASE_PASSWORD", default = ""),
    dbOptions: { useSSL: false }
};



// Create Gmail endpoint
endpoint gmail:Client gmailClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: accessToken,
            refreshToken: refreshToken,
            clientId: clientId,
            clientSecret: clientSecret
        }
    }
};

// Listen to port 9090
endpoint http:Listener listener {
    port: 9090
};

// Service for the employee data service
@http:ServiceConfig {
    basePath: "/records"
}
service<http:Service> EmployeeData bind listener {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/student/"
    }
    addStudentResource(endpoint httpConnection, http:Request request) {
        // Initialize an empty http response message
        http:Response response;
        Student studentData;
        // Extract the data from the request payload
        var payloadJson = check request.getJsonPayload();
        studentData = check <Student>payloadJson;

        // Check for errors with JSON payload using
        if (studentData.name == "" || studentData.marks == 0 ||
            studentData.studentId == 0 || studentData.email == "") {
            response.setTextPayload("Error : json payload should contain
             {name:<string>, marks:<int>,studentId:<int>}, {email:<string> ");
            response.statusCode = 400;
            _ = httpConnection->respond(response);
            done;
        }

        // Invoke insertData function to save data in the Mymysql database
        json ret = insertData(studentData.name, studentData.marks,
            studentData.studentId, studentData.email);

            // analysing of marks according to the classes given
            if(studentData.marks > 80) {
                 sendEmail(studentData.email,studentData.name,getCustomEmailTemplate(studentData.name, studentData.marks, "First Class"));
            }

            else if(studentData.marks > 60) {
                 sendEmail(studentData.email,studentData.name,getCustomEmailTemplate(studentData.name, studentData.marks,"Second Upper clas"));
            }

            else if(studentData.marks > 40) {
                 sendEmail(studentData.email,studentData.name,getCustomEmailTemplate(studentData.name, studentData.marks, "Second Class"));
            }
            else {
                sendEmail(studentData.email,studentData.name,getCustomEmailTemplate(studentData.name, studentData.marks,""));
            }
            
        // Send the response back to the client with the employee data
        response.setJsonPayload(ret);
        _ = httpConnection->respond(response);
    }
}

public function insertData(string name, int marks, int studentId, string email) returns (json){
    json updateStatus;
    string sqlString =
    "INSERT INTO EMPLOYEES (Name, Marks, StudentID, Email) VALUES (?,?,?,?)";
    // Insert data to SQL database by invoking update action
    var ret = employeeDB->update(sqlString, name, marks, studentId, email);
    // Use match operator to check the validity of the result from database
    match ret {
        int updateRowCount => {
            updateStatus = { "Status": "Data Inserted Successfully" };
        }
        error err => {
            updateStatus = { "Status": "Data Not Inserted", "Error": err.message };
        }
    }
    return updateStatus;
}
//send email function
function sendEmail(string stuEmail, string name, string body) {
    //Create html message
    gmail:MessageRequest messageRequest;
    messageRequest.recipient = stuEmail;
    messageRequest.sender = senderEmail;
    messageRequest.subject = "Examination";
    messageRequest.messageBody = body;
    messageRequest.contentType = gmail:TEXT_HTML;


    //Send mail
    var sendMessageResponse = gmailClient->sendMessage(userId, untaint messageRequest);
    string messageId;
    string threadId;
    match sendMessageResponse {
        (string, string) sendStatus => {
            (messageId, threadId) = sendStatus;
            log:printInfo("Sent email to " + stuEmail + " with message Id: " + messageId + " and thread Id:"
                    + threadId);
        }
        gmail:GmailError e => log:printInfo(e.message);
    }

    
}

// Template for the Email body
function getCustomEmailTemplate(string studentName, int marks, string class) returns (string) {
    string emailTemplate = "<h2> Hi " + studentName + " </h2>";
    emailTemplate = emailTemplate + "<h3> Thank you for your participation </h3>";
    emailTemplate = emailTemplate + "<p> Congrats you have obtained "+ marks + " marks</p>";
    emailTemplate = emailTemplate + "<p> Class Obtained:- " + class +" </p>";
    return emailTemplate;
}

function sendNotification() {
    //Retrieve the customer details from spreadsheet.
    string[][] values = getCustomerDetailsFromGSheet();
    int i = 0;
    //Iterate through each customer details and send customized email.
    foreach value in values {
        //Skip the first row as it contains header values.
        if (i > 0) {
            string studentName = value[0];
            int marks = value[1];
            string studentEmail = value[2];
            
        }
        i = i + 1;
    }
}

function getCustomerDetailsFromGSheet() returns (string[][]) {
    //Read all the values from the sheet.
    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");
    log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ;sheet name: "
            + sheetName);
    return values;
}



