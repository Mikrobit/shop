$( document ).ready(function() {

    $( "#message" ).on( "click", ".cancel-message", function() {
        $( this ).parent().parent().remove();
    });

});
