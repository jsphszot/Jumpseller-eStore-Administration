# Jumpseller-eStore-Administration

Just a couple of powershell scripts, bat files for execution, and some parameters in txt.

Basically just set up interactions using the Jumpseller API https://jumpseller.com/support/api/ to make life easier for my parents.
They run a family owned Brewpub/Brewery in Talagante, close to Santiago de Chile, and use the Jumpseller platform as an eStore.

store https://szot-brewpub.jumpseller.com/ ig https://www.instagram.com/cervezaszot/

It's a good platform but is missing some native functionality, but easily built hanging off of their API. 

The bat files are used to change a couple parameters (cd) and run each powershell script. 
The choice of these languages was such that my dad wouldn't have to worry installing anything new on his PCs, plus I was 12000kms away and 6hrs ahead at the moment and didn't want to do much tech support lol by phone.
Also JS wasn't an option due to the browser not allowing put requests to the JumpSeller API, was just easier in ps.

GetNewOrders.bat gets new orders that have been paid yet not processed, parses the json response and returns a user friendly txt with contact info and which products to pack.

ChangeStatusToDelivered.bat changes the status to all orders that have been Paid but not delivered, in a given range (input by user).

Future considerations are interacting directly with the Thermal Receipt printers already in use for the restaurant.
