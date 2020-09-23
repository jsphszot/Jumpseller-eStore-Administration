# Jumpseller-eStore-Administration

Powershell script, bat file for execution, and parameters in txt.

![Screenshot](SZOT-jumpsellerAPI.png = 250x)

Basically just set up interactions using the Jumpseller API https://jumpseller.com/support/api/ to make life easier for my parents.
They run a family owned Brewpub/Brewery in Talagante, close to Santiago de Chile, and use the Jumpseller platform as an eStore.

store https://szot-brewpub.jumpseller.com/ ig https://www.instagram.com/cervezaszot/

It's a good platform but is missing some native functionality, though easily built hanging off of their API. 


All resources are in the SZOT JumpSeller folder:

The bat files are used to change a couple parameters (cd) and run each powershell script. 
The choice of these languages was such that my dad wouldn't have to worry installing anything new on his PCs (sorry Python), plus I was 12000kms away and 6hrs ahead at the moment and didn't want to do much tech support by phone lol.
JS wasn't a great option either due to the browser not allowing put requests to the JumpSeller API... was just easier in ps.

GetNewOrders.bat gets new orders that have been paid but not yet processed, parses the json response and returns a user friendly txt with contact info and which products to pack (NewOrders.txt).

ChangeStatusToDelivered.bat changes the status of all orders in a given range (input by user) that have been Paid but not delivered, to delivered.

Future considerations are interacting directly with the Thermal Receipt printers already in use for the restaurant.
