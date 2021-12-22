# Dengue_mdelling
Dengue Modelling based on Netlogo
This Netlogo model attempts to capture Dengue epidemic using Host & Vector layer.
The goal is to find how Dengue spreads , account for seasonal variation in Model , Visualization of different control measures and overall provide a robust modelling to account for actual epidempic impact.

Proposed simulation framework will simulate Dengue epidemic using Agent based modelling ( ABM )
ABM will help us interaction between different agents in play and the environmental considerations

Agents will be mainly segregated as:
  Host layer ( Humans )
  Vector layer ( Mosquitoes )

Simulation engine for below is developed ( current status )
	Human stage transition:  Susceptible -> Infected - > Recovered / Dead 
	Vector stage changes : Eggs -> Larva - Pupa - > Adult
	Bite based on hunger for female vector
	Spread of infection based on bite
	Vector reproduction via Laying eˀgs in breeding zones
	Time step for day and night
	Host and Vector mobility
	Human killing vector probabilistically
	Eventual vector death
	Immunity for immunity duration
