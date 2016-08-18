function add_to_wishlist( product, quantity ) {
    // Get the current wishlist
    var wishlist = JSON.parse( localStorage.getItem("wishlist") );

    if( wishlist == null ) { wishlist = {}; }

    // Is the product already in the wishlist?
    if( wishlist[product] ) {
        // Add one
        wishlist[product]["quantity"]++;
        localStorage.setItem( "wishlist", JSON.stringify(wishlist) );
    } else {
        // Store it
        wishlist[product] = {};
        wishlist[product]["quantity"] = quantity;

        localStorage.setItem( "wishlist", JSON.stringify(wishlist) );
    }

    // Log
    console.log( localStorage.getItem("wishlist") );

    //localStorage.clear();
}

function empty_wishlist() {
    localStorage.setItem( "wishlist", "{}" );
}

function sub_from_wishlist( product, quantity ) {
    // Get the current wishlist
    var wishlist = JSON.parse( localStorage.getItem("wishlist") );

    if( wishlist == null ) { wishlist = {}; }

    // Is the product in the wishlist?
    if( wishlist[product] ) {
        // Sub one
        wishlist[product]["quantity"]--;
        if( wishlist[product]["quantity"] < 1 ) {
            delete wishlist[product];
        }
        localStorage.setItem( "wishlist", JSON.stringify(wishlist) );
    }

    // Log
    console.log( localStorage.getItem("wishlist") );

    //localStorage.clear();
}
