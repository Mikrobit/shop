$( document ).ready(function() {
    
    // Add a full variation block, with name and option
    $( "#variations" ).on( "click", ".var_add_variation", function() {
        $( ".variation:first" ).clone().appendTo( "#variations" );
        $( ".variation:last" ).css( "display", "block" );
        $( this ).remove();
    });

    // Add a full variation block, with name and option, without removing the plus sign
    $( "#variations" ).on( "click", ".var_add_first_variation", function() {
        $( ".variation:first" ).clone().appendTo( "#variations" );
        $( ".variation:last" ).css( "display", "block" );
    });

    // Add an option to an existing variation
    $( "#variations" ).on( "click", ".var_add_value", function() {
        $( ".var_value:first" ).clone().appendTo( $( this ).parent() );
        $( this ).remove();
    });

    // Remove a full variation block
    $( "#variations" ).on( "click", ".var_del_variation", function() {
        $( this ).parent().parent().parent().remove();
    });

    // Remove an option
    $( "#variations" ).on( "click", ".var_del_value", function() {
        // Remove the option block
        $( this ).parent().remove();
    });
});

