# MTA-fire-elements
A resource to create serverside controllable fire in MTA. Possible usage is for scripting a fire brigade where players have to extinghuish fires to earn money - there is also an event to catch the player when he puts a fire out).



Basic functions and events (only serverside):
```
fire uFire = createFireElement(int x, int y, int z, int size, bool decaying)
-- x,y,z = the position of your fire
-- size = the size of your fire (from 1 to 3, where 1 is the smallest)
-- decaying = a boolean whether your fire extinguishes itself after some time (can be edited in fire_s.lua settings)

destroyFireElement(fire fire, player destroyer)
-- if there is no destroyer, the fire will still go out (destroyer refers to the player who should be in charge of extinguishing)

addEventHandler("fireElements:onFireExtinguish", fire fire, 
  function(player destroyer, int size)
    -- TODO: make something happen when the fire was extinguished
    
    -- fire = the previously created fire
    -- inside handler function:
      -- destroyer refers to the player who has extinguished the fire (otherwise nil)
      -- size represents the size the fire has before it went out (useful for determining which player did the most work when scripting something like a fire brigade)
  end
)
```




two keyboard broke in the process of writing `extinguish`
