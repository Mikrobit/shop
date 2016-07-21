function add_to_cart( product, quantity ) {
    var cart = {};
    // Get the current cart
    cart = JSON.parse( localStorage.getItem("cart") );

    // Is the product already in the cart?
    if( cart && cart[product] ) {
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
