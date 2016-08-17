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
    //console.log( JSON.parse( localStorage.getItem("cart") ) );
    console.log( localStorage.getItem("cart") );

    //localStorage.clear();
}
