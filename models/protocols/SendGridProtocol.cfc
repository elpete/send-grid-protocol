component extends="cbmailservices.models.AbstractProtocol" {

    /**
    * Initialize the Send Grid protocol
    *
    * @properties A map of configuration properties for the protocol
    */
    public SendGridProtocol function init( struct properties = {} ) {
        super.init( argumentCollection = arguments );

        if ( ! structKeyExists( properties, "apiKey" ) ) {
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
        var rtnStruct   = {error=true, errorArray=[], messageID=''};
        var mail = payload.getMemento();

        var body = {
            "from": {
                "email": mail.from
            }
        };

        if ( structKeyExists( mail, "fromName" ) && mail.fromName != "" ) {
            body[ "from" ][ "name" ] = mail.fromName;
        }

        if ( structKeyExists( mail, "replyto" ) && mail.replyto != "" ) {
            body[ "reply_to" ][ "email" ] = mail.replyto;
        }


        body[ "subject" ] = mail.subject;

        var tos = isArray( mail.to ) ? mail.to : arraySlice( mail.to.split( "[,;]\s*" ), 1 );
        var personalization = {
            "to": tos.map( function( to ) {
                return { "email": to };
            } )
        };

        if ( mail.keyExists( "bcc" )  && ! mail.bcc.isEmpty() ) {
            mail.bcc = isArray( mail.bcc ) ? mail.bcc : arraySlice( mail.bcc.split( "[,;]\s*" ), 1 );
            if ( ! mail.bcc.isEmpty() ) {
                personalization[ "bcc" ] = mail.bcc.map( function( address ) {
                    return { "email" = address };
                } );
            }
        }
        
        if ( mail.keyExists( "cc" ) && ! mail.cc.isEmpty() ) {
            mail.cc = isArray( mail.cc ) ? mail.cc : arraySlice( mail.cc.split( "[,;]\s*" ), 1 );
            if ( ! mail.cc.isEmpty() ) {
                personalization[ "cc" ] = mail.cc.map( function( address ) {
                    return { "email" = address };
                } );
            }
        }

        if ( structKeyExists( mail, "additionalInfo" ) && isStruct( mail.additionalInfo ) ) {
            if ( structKeyExists( mail.additionalInfo, "categories" ) ) {
                if ( ! isArray( mail.additionalInfo.categories ) ) {
                    mail.additionalInfo.categories = listToArray( mail.additionalInfo.categories );
                }
                body[ "categories" ] = mail.additionalInfo.categories;
            }

            if ( structKeyExists( mail.additionalInfo, "customArgs" ) ) {
                body[ "custom_args" ] = mail.additionalInfo.customArgs;
            }
        }

        var type = structKeyExists( mail, "type" ) ? mail.type : "plain";

        if ( type == "template" ) {
            body[ "template_id" ] = mail.body;
            personalization[ "substitutions" ] = mail.bodyTokens;
        }
        else {
            body[ "content" ] = [ {
                "type": "text/#type#",
                "value": mail.body
            } ];
        }

        body[ "personalizations" ] = [ personalization ];

        cfhttp( url = "https://api.sendgrid.com/v3/mail/send", method = "POST" ) {
            cfhttpparam( type = "header", name = "Authorization", value="Bearer #getProperty( "apiKey" )#" );
            cfhttpparam( type = "header", name = "Content-Type", value="application/json" );
            cfhttpparam( type = "body", value = serializeJson( body ) );
        };

        if ( left( cfhttp.status_code, 1 ) != "2" && left( cfhttp.status_code, 1 ) != "3"  ) {
            rtnStruct.errorArray = deserializeJSON( cfhttp.filecontent ).errors;
        }
        else {
            rtnStruct.error = false;
        }
        if ( StructKeyExists(cfhttp,'responseheader') AND StructKeyExists(cfhttp.responseheader,'X-Message-Id') ) {
            rtnStruct.messageID = cfhttp.responseheader['X-Message-Id'];
        }

        return rtnStruct;
    }

}
