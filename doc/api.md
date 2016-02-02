Product api
===========

For nicer results and substitute ``-i`` with ``-s`` and pipe the json result to ``| jq '.'``

Get one product info
----
```
#!sh
    curl -i http://api.example.com/product/$id
```

where $id is a product id.

Create a product
----
```
#!sh
    curl -i -X POST -d "product=$json" http://api.example.com/product/
```

where $json is something like:

```
#!json
    {
        "name"      : {
            "EN": "Product name",
            "IT": "Nome prodotto"
        },
        "short_desc": {
            "EN": "A short description",
            "IT": "Una breve descrizione"
        },
        "long_desc" : {
            "EN": "A much, much longer description",
            "IT": "Una descrizione molto, molto più lunga"
        },
        "variations": {
            "colors": {
                "EN":[ "blue","green","black" ],
                "IT":[ "blu","verde","nero" ]
            },
            "sizes": {
                "EN":[ "s", "m", "l", "xl" ],
                "IT":[ "s","m","l","xl" ]
            }
        },
        "price"     : 20,
        "taxes"     : 0,
        "stock"     : 1,
        "discount"  : 0,
        "published" : 1,
        "images"    : [
            {
                "caption"   : {
                    "EN": "Image 1 caption",
                    "IT": "Testo alt"
                },
                "url"       : "/img/url1.png"
            },
            {
                "caption"   : {
                    "EN": "Image 2 caption"
                },
                "url"       : "/img/url2.png"
            }
            ]
    }
```

Modify an existing product
----
```
#!sh
    curl -i -X PUT -d "product=$json" http://api.example.com/product/$id
```

where $json is exactly like the above example and $id is the id of the product to be modified

Delete a product
----
```
#!sh
    curl -i -X DELETE http://api.example.com/product/$id
```

where $id is a product id.

List category's products
----
```
#!sh
    curl -i http://api.example.com/product/list/$id
```

where $id is the category id.

Category api
============

Basically the same as product's api, using the ``/category`` prefix.

Two significant additions withstand:

Add a product to a category
----
```
#!sh
    curl -i http://api.example.com/category/$id/add/$pid
```

where $id is the category id and $pid is the product id.

Remove a product from a category
----
```
#!sh
    curl -i http://api.example.com/category/$id/del/$pid
```

where $id is the category id and $pid is the product id.

User api
========

Add a user
---
```
#!sh
    curl -i -X POST -d "user=$ujson" http://api.example.com/user/
```

```
#!json
    {
        "email": "me@here.sh",
        "cart": [1,2,4],
        "wishlist": [3],
        "name": "Mirko",
        "surname": "Iannella",
        "city": "Perugia",
        "province": "PG",
        "city_code": "06120",
        "address": "Via di casa mia, 2",
        "country": "Italy",
        "telephone": "+39.0123456789",
        "cc_number": "0123 4302 6300 2985 9201",
        "cc_cvd": "242",
        "cc_valid_m": "10",
        "cc_valid_y": "2014",
        "paypal": "me.paying@here.sh"
    }
```

Orders api
==========

Place an order
---
```
#!sh
    curl -i -X POST -d "order=$ojson" http://api.example.com/order/
```

```
#!json
    {
        "user": "mirko@example.com",
        "total": 42.73,
        "pay_method": "paypal",
        "name": "Mirko",
        "surname": "Iannella",
        "city": "Perugia",
        "province": "PG",
        "city_code": "06120",
        "address": "Via di casa mia, 2",
        "country": "Italy",
        "telephone": "+39.0123456789"
    }
```

List orders
-----------
```
#!sh
    curl -i http://api.example.com/order/list
```

Modify an order
---------------
```
#!sh
    curl -i -X PUT -d "order=$ojson" http://api.example.com/order/$oid
```

Delete an order
---------------
```
#!sh
    curl -i -X DELETE -d "order=$ojson" http://api.example.com/order/$oid
```

