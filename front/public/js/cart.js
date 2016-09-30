function add_to_cart( api, product, quantity, email='' ) {
    // Get the current client-side cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null ) cart = {};
    if( cart == {} || email !== '' ) {
        _get_db_cart( api, product, quantity, email, _add_to_cart_callback );
    }
}

function _add_to_cart_callback( api, product, quantity, email, cart ) {
    // Is the product already in the cart?
    if( cart[product] ) {
        // Add one
        cart[product]["quantity"] += quantity;
        localStorage.setItem( "cart", JSON.stringify(cart) );
    } else {
        // Store it
        cart[product] = {};
        cart[product]["quantity"] = quantity;

        localStorage.setItem( "cart", JSON.stringify(cart) );
    }
    if( email !== '') _update_db_cart( api, email, cart );
    get_quantity(product);
}

function sub_from_cart( api, product, quantity, email='' ) {
    // Get the current cart
    var cart = JSON.parse( localStorage.getItem("cart") );

    if( cart == null ) cart = {};
    if( cart == {} || email !== '' ) {
        _get_db_cart( api, product, quantity, email, _sub_from_cart_callback );
    }
}

function _sub_from_cart_callback( api, product, quantity, email, cart ) {
    // Is the product in the cart?
    if( cart[product] ) {
        // Sub one
        cart[product]["quantity"] -= quantity;
        if( cart[product]["quantity"] < 1 ) {
            delete cart[product];
        }
        localStorage.setItem( "cart", JSON.stringify(cart) );
    }
    if( email !== '') _update_db_cart( api, email, cart );
    get_quantity(product);
}

function empty_cart( api, email ) {
    localStorage.setItem( "cart", "{}" );
}

function get_quantity( product ) {
    var counter = document.getElementById( product + '_in_cart');
    var cart = JSON.parse( localStorage.getItem("cart") );

    counter.value = 0;
    if( typeof cart[product] !== 'undefined' ) {
        counter.value = cart[product]["quantity"];
    }
}

function _update_db_cart( api, email, cart ) {
    var r = new XMLHttpRequest();
    r.open("POST", api + "/user/" + email + "/cart/update", true);

    r.onreadystatechange = function () {
        if ( r.readyState != 4 && ( r.status != 200 && r.status != 201 ) ) {
            console.log("Maporc...");
            return;
        }
    };

    var data = new FormData();
    data.append('cart', JSON.stringify(cart));

    r.send( data );
}

function _get_db_cart( api, product, quantity, email, callback ) {
    var cart = {};
    // Get server-side cart
    var r = new XMLHttpRequest();
    r.open("GET", api + "/user/" + email + "/cart", true);
    r.send();
    r.onreadystatechange = function () {
        if ( r.readyState === 4 && r.status === 200 ) {
            cart = JSON.parse( r.responseText );
            callback( api, product, quantity, email, cart );
        }
    };
}

