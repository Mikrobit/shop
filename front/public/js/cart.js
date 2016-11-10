'use strict;';

function add_to_cart( api, product, quantity, email='' ) {
	// Get the current client-side cart
	var cart = JSON.parse( localStorage.getItem("cart") );

    console.log("Cazzo ci fai qua?" + cart);
	if( cart == null ) cart = empty_cart();
	if( cart == {} && email !== '' ) {
		_get_db_cart( api, product, quantity, email, _add_to_cart_callback );
		return;
	}

	_add_to_cart_callback( api, product, quantity, email, cart );
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

	if( cart == null ) cart = empty_cart();
	if( cart == {} && email !== '' ) {
		_get_db_cart( api, product, quantity, email, _sub_from_cart_callback );
		return;
	}
	_sub_from_cart_callback( api, product, quantity, email, cart );
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
	console.log("Empty");
	localStorage.setItem( "cart", "{}" );
	if( email ) _update_db_cart( api, email, '{}' );
    return {};
}

function get_quantity( product ) {
	var counter = document.getElementById( product + '_in_cart');
	var cart = JSON.parse( localStorage.getItem("cart") );

	counter.value = 0;
	if( cart != null && typeof cart[product] !== 'undefined' ) {
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
	        if( cart == null ) empty_cart();
			callback( api, product, quantity, email, cart );
		}
	};
}

function* iterate_object(o) {
	var keys = Object.keys(o);
	for(var i=0; i<keys.length;i++) {
		yield [keys[i], o[keys[i]]];
	}
}

function cart_table(api) {
    var tbl = document.getElementById('products');
    var products = JSON.parse( localStorage.getItem("cart") );
    total = 0;
    for( var [pid, val] of iterate_object(products) ) {
        product_row(api, pid, val["quantity"]);
    }
}

function product_row(api, pid, quantity) {
	var product = {};
	// Get product data
	var r = new XMLHttpRequest();
	r.open("GET", api + "/product/" + pid, true);
	r.send();
	r.onreadystatechange = function () {
		if ( r.readyState === 4 && r.status === 200 ) {
			product = JSON.parse( r.responseText );
			_product_row_callback( api, product, quantity );
		}
	};
}

function _product_row_callback(api, product, quantity) {
	var tbl=document.getElementById('products');
	var tr = tbl.insertRow();
    tr.className = 'product_row';

    // Image
    var td = tr.insertCell();
    td.className = 'image';
    var img = document.createElement('img');
    img.setAttribute('src', product['images'][0]['thumb']['it']);
    td.appendChild(img);

    // Description
    var td1 = tr.insertCell();
    td1.classname = 'description';
    var description = document.createElement('h3');
    description.innerHTML = product['short_desc']['it'];
    td1.appendChild(description);

    // Quantity
    var td2 = tr.insertCell();
    td2.classname = 'quantity';
    var q = document.createElement('h3');
    q.innerHTML = quantity;
    td2.appendChild(q);

    // Price
    var td3 = tr.insertCell();
    td3.classname = 'price';
    var p = document.createElement('h3');
    p.innerHTML = (product['price'] * quantity).toFixed(2) + ' &euro;';
    td3.appendChild(p);

    // Sorry, I can't use js promises, so I need to create the total row
    // each time I add a product to the table.
    // This sucks.

    total += product['price'] * quantity;

    // update cart's total
    localStorage.setItem( "total", total );

    total_row();
}

function total_row() {
    // Remove previous total row
    var prev_total_row = document.getElementsByClassName('total_row')[0];
    if( prev_total_row ) {
        prev_total_row.parentElement.removeChild(prev_total_row);
    }

    // Create new total row
	var tbl=document.getElementById('products');
	var tr = tbl.insertRow();
    tr.className = 'total_row';

    var td = tr.insertCell();
    td.colSpan=3;
    var h30 = document.createElement('h3');
    h30.innerHTML = "Total";
    td.appendChild(h30);

    var td1 = tr.insertCell();
    var h31 = document.createElement('h3');
    h31.innerHTML = total.toFixed(2) + ' &euro;';
    td1.appendChild(h31);
}
