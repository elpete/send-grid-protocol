# Send Grid Protocol

[![Build Status](https://travis-ci.org/elpete/send-grid-protocol.svg?branch=master)](https://travis-ci.org/elpete/send-grid-protocol)

## A [`cbmailservices`](https://github.com/ColdBox/cbox-mailservices) protocol for sending email via Send Grid

> In `cbmailservices` parlance, a `protocol` is a method of sending an email.  Protocols can be switched out based on environment settings making it easy to log a mail to a file in development, send it to an in-memory store for asserting against in tests, and sending to real services in production.

### Configuration

You can configure SendGrid as your protocol inside your `mailsettings` in your `config/ColdBox.cfc`.  It is recommended you store your API key outside version control in either server ENV settings or Java properties.  This approach also lets you easily swap out dev and production keys based on the environment.

```
mailsettings = {
	from = "eric@cfcasts.com",
	tokenMarker = "@",
	protocol = {
		class = "sendgridprotocol.models.protocols.SendGridProtocol",
		properties = {
			apiKey = application.system.getProperty( "SEND_GRID_KEY" )
		}
	}
};
```

### Template Emails

To send an email using a SendGrid template, you need to set the mail type to `template`:
```
var mail = mailService.newMail(
    to = user.getEmail(),
    subject = "Welcome to my site!",
    type = "template"
);
```

Then set the body to the template id in SendGrid:
```
mail.setBody( templateId );
```

Any tokens to be parsed by the template can be set as normal:
```
mail.setBodyTokens( {
    "[%username%]" = interceptData.user.getUsername()
} );
```

### Plain Emails

To send a plain text email, set the `type` to `plain`:
```
var mail = mailService.newMail(
    to = user.getEmail(),
    subject = "Welcome to my site!",
    type = "template"
);
```

The body of the email is what will be sent.
```
mail.setBody( "My plain text email here.  I can still use @placeholders@, of course." );
```

### Categories

You can attach a list or array of categories for your email by setting them on the `additionalInfo.categories` field of the mail.
```
mail.setAdditionalInfoItem( "categories", "marketing" );
mail.setAdditionalInfoItem( "categories", "lists,of,categories" );
mail.setAdditionalInfoItem( "categories", [ "or", "as", "an", "array" ] );
```
