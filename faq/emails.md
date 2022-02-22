---
parent: Frequently Asked Questions
---

# How can I check emails sent by the system?

Starting in version `3.3.0` an additional service called [smtp4dev] is included to support sending and receving emails.  By using this service there is no requirement to have an email server configured for local development.

All emails sent by CluedIn will be received and stored by the service.
You can view the emails by opening http://localhost:25258 in a browser.

All emails are stored in a database under the path `<env>\data\smtp4dev`

> You can change the port used by updating `CLUEDIN_SMTP_HTTP_LOCALPORT` in your `.env` file if it conflicts with another service on your machine.

# What if I don't want to use a real email service?

You can configure where CluedIn sends emails by updating the `.env` file

+ `CLUEDIN_EMAIL_HOST` - specifies the host address where emails will be sent
+ `CLUEDIN_EMAIL_PORT` - specifies the port of the email host
+ `CLUEDIN_EMAIL_USER` - specifies the username when connecting
+ `CLUEDIN_EMAIL_PASS` - specifies the password when connecting
+ `CLUEDIN_EMAIL_SSL` - specifies the connection should be secure

## Writing emails to disk - (pre 3.3.0)

Alternatively, you can simply write emails to disk by setting `CLUEDIN_EMAIL_DIR` to a directory (e.g. `/emails`).  The directory will be created under the environment that is running CluedIn.
Emails will be written in `.eml` format and require an application such as Microsoft Outlook to be opened and easily read.

[smtp4dev]: https://github.com/rnwood/smtp4dev]
