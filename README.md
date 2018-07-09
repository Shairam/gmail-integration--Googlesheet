# gmail-integration--Googlesheet

Pre-requisites

    Ballerina Distribution
    Ballerina IDE plugins (IntelliJ IDEA and VSCode
    Go through the following steps to obtain credetials and tokens for both Google Sheets and Gmail APIs.
        Visit Google API Console, click Create Project, and follow the wizard to create a new project.
        Enable both Gmail and Google Sheets APIs for the project.
        Go to Credentials -> OAuth consent screen, enter a product name to be shown to users, and click Save.
        On the Credentials tab, click Create credentials and select OAuth client ID.
        Select an application type, enter a name for the application, and specify a redirect URI (enter https://developers.google.com/oauthplayground if you want to use OAuth 2.0 playground to receive the authorization code and obtain the access token and refresh token).
        Click Create. Your client ID and client secret appear.
        In a separate browser window or tab, visit OAuth 2.0 playground, select the required Gmail and Google Sheets API scopes, and then click Authorize APIs.
        When you receive your authorization code, click Exchange authorization code for tokens to obtain the refresh token and access token.


You must configure the ballerina.conf configuration file with the above obtained tokens, credentials and other important parameters as follows. ACCESS_TOKEN="access token"
  CLIENT_ID="client id"
  CLIENT_SECRET="client secret"
  REFRESH_TOKEN="refresh token"
  SPREADSHEET_ID=""
  SHEET_NAME="sheet name of your Goolgle Sheet. For example in above example, SHEET_NAME="Stats"
  SENDER="email address of the sender"
  USER_ID="mail address of the authorized user. You can give this value as, me"
