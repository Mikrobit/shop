function add_to_cart( api, email, product, quantity ) {
    // Get the current client-side cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null || cart == {} ) {
        cart = _get_db_cart( api, email );
    }

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

    // Update the db's cart
    var r = new XMLHttpRequest();
    r.open("POST", api + "/" + email + "/cart", true);
    r.onreadystatechange = function () {
    if (r.readyState != 4 && r.status != 200) {
        console.log("Maporc...");
        return
    }
    r.send(cart);
}

function sub_from_cart( api, email, product, quantity ) {
    // Get the current cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null || cart == {} ) {
        cart = _get_db_cart( api, email );
    }

    // Is the product in the cart?
    if( cart[product] ) {
        // Sub one
        cart[product]["quantity"]--;
        if( cart[product]["quantity"] < 1 ) {
            delete cart[product];
        }
        localStorage.setItem( "cart", JSON.stringify(cart) );
    }
}

function empty_cart( api, email ) {
    localStorage.setItem( "cart", "{}" );
}

function _get_db_cart ( api, email ) {
    cart = {};
    // Get server-side cart
    var r = new XMLHttpRequest();
    r.open("GET", api + "/" + email + "/cart", true);
    r.onreadystatechange = function () {
        if (r.readyState == 4 && r.status == 200) {
            cart = JSON.parse( r.response );
            if( cart == null ) cart = {};
        }
    };
    return cart;
}
