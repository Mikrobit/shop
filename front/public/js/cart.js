function add_to_cart( product, quantity ) {
    // Get the current cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null ) { cart = {}; }

    // Is the product already in the cart?
    if( cart[product] ) {
        // Add one
        cart[product]["quantity"]++;
        localStorage.setItem( "cart", JSON.stringify(cart) );
    } else {
        // Store it
        cart[product] = {};
        cart[product]["quantity"] = quantity;

        localStorage.setItem( "cart", JSON.stringify(cart) );
    }

    // Log
    console.log( localStorage.getItem("cart") );

    //localStorage.clear();
}

function empty_cart() {
    localStorage.setItem( "cart", "{}" );
}

function sub_from_cart( product, quantity ) {
    // Get the current cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null ) { cart = {}; }

    // Is the product in the cart?
    if( cart[product] ) {
        // Sub one
        cart[product]["quantity"]--;
        if( cart[product]["quantity"] < 1 ) {
            delete cart[product];
        }
        localStorage.setItem( "cart", JSON.stringify(cart) );
    }

    // Log
    console.log( localStorage.getItem("cart") );

    //localStorage.clear();
}
