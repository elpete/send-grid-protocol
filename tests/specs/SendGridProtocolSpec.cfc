component extends="testbox.system.BaseSpec" {

    variables.apiKey = "038113416a34c7b71a50e4bfff075b34";

    function run() {
        describe( "Send Grid Protocol", function() {
            describe( "instantiation", function() {
                it( "can be instantiated", function() {
                    var protocol = new root.models.protocols.SendGridProtocol({ apiKey = variables.apiKey });

                    expect( protocol ).toBeInstanceOf( "root.models.protocols.SendGridProtocol" );
                } );

                it( "requires an api key to be passed in the properties", function() {
                    expect( function() {
                        var protocol = new root.models.protocols.SendGridProtocol();
                    } ).toThrow();
                } );
            } );
        } );
    }

}