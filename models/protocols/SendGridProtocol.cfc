component extends="cbmailservices.models.AbstractProtocol" {

	/**
	 * Initialize the Send Grid protocol
	 *
	 * @properties A map of configuration properties for the protocol
	 */
	public SendGridProtocol function init( struct properties = {} ) {
		variables.name = "SendGrid";
		super.init( argumentCollection = arguments );

		if ( !structKeyExists( properties, "apiKey" ) ) {
			throw( "A Send Grid API key is required to use this protocol.  Please pass one in via the properties struct in your `config/ColdBox.cfc`." );
		}

		return this;
	}

	/**
	 * Send a message via the Send Grid API
	 *
	 * @payload The payload to deliver
	 */
	public function send( required cbmailservices.models.Mail payload ) {
		var rtnStruct = {
			error     : true,
			messages  : [],
			messageID : ""
		};
		var mail = payload.getMemento();

		var body = { "from" : { "email" : mail.from } };

		if ( structKeyExists( mail, "fromName" ) && mail.fromName != "" ) {
			body[ "from" ][ "name" ] = mail.fromName;
		}

		if ( structKeyExists( mail, "replyto" ) && mail.replyto != "" ) {
			body[ "reply_to" ][ "email" ] = mail.replyto;
		}


		body[ "subject" ] = mail.subject;

		var tos             = normalizeEmailsToArray( mail.to );
		var personalization = {
			"to" : tos.map( function( to ) {
				return { "email" : to };
			} )
		};

		var ccs = [];
		if ( mail.keyExists( "cc" ) ) {
			ccs = normalizeEmailsToArray( mail.cc ).filter( function( email ) {
				return !arrayContainsNoCase( tos, email );
			} );
			if ( !ccs.isEmpty() ) {
				personalization[ "cc" ] = ccs.map( function( address ) {
					return { "email" : address };
				} );
			}
		}

		var bccs = [];
		if ( mail.keyExists( "bcc" ) ) {
			bccs = normalizeEmailsToArray( mail.bcc ).filter( function( email ) {
				return !arrayContainsNoCase( tos, email ) && !arrayContainsNoCase( ccs, email );
			} );
			if ( !bccs.isEmpty() ) {
				personalization[ "bcc" ] = bccs.map( function( address ) {
					return { "email" : address };
				} );
			}
		}

		if ( structKeyExists( mail, "additionalInfo" ) && isStruct( mail.additionalInfo ) ) {
			if ( structKeyExists( mail.additionalInfo, "categories" ) ) {
				if ( !isArray( mail.additionalInfo.categories ) ) {
					mail.additionalInfo.categories = listToArray( mail.additionalInfo.categories );
				}
				body[ "categories" ] = mail.additionalInfo.categories;
			}

			if ( structKeyExists( mail.additionalInfo, "customArgs" ) ) {
				body[ "custom_args" ] = mail.additionalInfo.customArgs;
			}

			if ( structKeyExists( mail.additionalInfo, "trackingSettings" ) ) {
				body[ "tracking_settings" ] = mail.additionalInfo.trackingSettings;
			}

			if ( structKeyExists( mail.additionalInfo, "mailSettings" ) ) {
				body[ "mail_settings" ] = mail.additionalInfo.mailSettings;
			}

			if ( structKeyExists( mail.additionalInfo, "batchID" ) ) {
				body[ "batch_id" ] = mail.additionalInfo.batchID;
			}
		}

		var type = structKeyExists( mail, "type" ) ? mail.type : "plain";

		if ( type == "template" ) {
			body[ "template_id" ]                      = mail.body;
			personalization[ "dynamic_template_data" ] = mail.bodyTokens;
		} else {
			body[ "content" ] = [
				{
					"type"  : "text/#type#",
					"value" : mail.body
				}
			];
		}

		body[ "personalizations" ] = [ personalization ];

		if ( structKeyExists( mail, "mailparams" ) && isArray( mail.mailparams ) && arrayLen( mail.mailparams ) ) {
			body[ "attachments" ] = mail.mailParams
				.filter( function( mailParam ) {
					return structKeyExists( mailParam, "file" );
				} )
				.map( function( mailParam ) {
					return {
						"content"  : toBase64( fileReadBinary( mailParam.file ) ),
						"filename" : listLast( mailParam.file, "/" )
					};
				} );
		}

		var sendGridResponse = "";
		try {
			cfhttp(
				url          = "https://api.sendgrid.com/v3/mail/send",
				method       = "POST",
				result       = "sendGridResponse",
				timeout      = 10,
				throwOnError = "true"
			) {
				cfhttpparam(
					type  = "header",
					name  = "Authorization",
					value = "Bearer #getProperty( "apiKey" )#"
				);
				cfhttpparam(
					type  = "header",
					name  = "Content-Type",
					value = "application/json"
				);
				cfhttpparam( type = "body", value = serializeJSON( body ) );
			};
		} catch ( any e ) {
			log.error( "An unknown error occurred when sending the http request to SendGrid", e );
			rtnStruct.messages = [ "An unknown error occurred" ];
			return rtnStruct;
		}

		if ( !isStruct( sendGridResponse ) ) {
			log.error( "An unknown error occurred when sending the http request to SendGrid. No response was returned." );
			rtnStruct.messages = [ "An unknown error occurred. No response was returned." ];
		}

		if (
			!structKeyExists( sendGridResponse, "responseheader" ) || !structKeyExists(
				sendGridResponse.responseheader,
				"status_code"
			)
		) {
			log.error( "An unknown error occurred when sending the http request to SendGrid", sendGridResponse );
			rtnStruct.messages = [ "An unknown error occurred" ];
		} else if (
			left( sendGridResponse.responseheader.status_code, 1 ) != "2" && left(
				sendGridResponse.responseheader.status_code,
				1
			) != "3"
		) {
			rtnStruct.messages = deserializeJSON( sendGridResponse.filecontent ).errors;
		} else {
			rtnStruct.error = false;
		}

		if (
			structKeyExists( sendGridResponse, "responseheader" ) AND structKeyExists(
				sendGridResponse.responseheader,
				"X-Message-Id"
			)
		) {
			rtnStruct.messageID = sendGridResponse.responseheader[ "X-Message-Id" ];
		}

		return rtnStruct;
	}

	private array function normalizeEmailsToArray( required any emails ) {
		if ( isArray( arguments.emails ) ) {
			return arguments.emails;
		}

		if ( !isValid( "String", arguments.emails ) ) {
			return [ arguments.emails ];
		}

		if ( len( arguments.emails ) <= 0 ) {
			return [];
		}

		return arraySlice( arguments.emails.split( "[,;]\s*" ), 1 );
	}

}
