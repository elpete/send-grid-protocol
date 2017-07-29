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
        var rtnStruct   = {error=true, errorArray=[]};
        var mail = payload.getMemento();

        var body = {
            "from": {
                "email": mail.from
            }
        };
        
        body[ "subject" ] = mail.subject;
        
        if( structKeyExists( mail, "additionalInfo" ) && isStruct( mail.additionalInfo ) && structKeyExists( mail.additionalInfo, "categories" ) ){
            body[ "categories" ] = listToArray( mail.additionalInfo.categories );            
        }
        
        var personalization = {
            "to": [ {
                "email": mail.to
            } ]
        };

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
            cfhttpparam( type = "header", name = "Authorization" value="Bearer #getProperty( "apiKey" )#" );
            cfhttpparam( type = "header", name = "Content-Type" value="application/json" );
            cfhttpparam( type = "body", value = serializeJson( body ) );
        }

        if ( left( cfhttp.status_code, 1 ) != "2" && left( cfhttp.status_code, 1 ) != "3"  ) {
            rtnStruct.errorArray = deserializeJSON( cfhttp.filecontent ).errors;
        }
        else {
            rtnStruct.error = false;
        }

        return rtnStruct;
    }

}
