extensions [ gis csv table ]

globals
[
  sites roads districts SL
  illnessDuration
  ACTION-RADIUS
  HOUSE-SIZE
  HUMAN-ACTION-RADIUS
  HUMAN-SIZE
  MOSQUITO-SIZE
  BREEDING-ZONE-SIZE
  HUMAN_KILLING_RANGE
  WORKING_HOUR?
  DEATH_BY_HUMAN_PROBABILITY
  BREEDING-RANGE
  AEDESP-MAX-AGE
  flag
  mylist
  counter
  cnt
  chance-of-death
  pune-dataset

]


patches-own [ward-name waterAccumulation]
turtles-own []

breed [admin-labels admin-label]
admin-labels-own [name]

breed[houses house]
breed[workZones workZone]
breed[breedingZones breedingZone]
breed[people human]
breed[aedesp aedesi]


people-own[
  age
  state ;;Susceptible , Infected , Dead , Recovered
  daysSinceInfection
  worker?
  name
  coMorbid?
  male?
  my-house
  my-workplace
  ward
]

aedesp-own
[
 age
 mated?
 female?
 laidEggs?
 life_stage
 infected?
 maleReproductiveDelay
 hunger
 movement_speeds
 life_stage_ticks

]



workZones-own[
  name ;; C:String: Work zone name
]

houses-own[
  group
  district
  persons
  name
]

breedingZones-own[
]


to setup
  clear-all
  reset-ticks
  set pune-dataset gis:load-dataset "Pune.geojson"
  set-global-variables
  ;set-pop -- commenting as we have dedicated function to load population
  ;set-house -- move to set-pop
  end


to draw
clear-drawing
reset-ticks
gis:set-world-envelope gis:envelope-of pune-dataset
   ;;gis:set-transformation world-envelope (list min-pxcor max-pxcor min-pycor max-pycor)
gis:set-drawing-color red
ask patches [set pcolor white set ward-name "Outside"]
gis:apply-coverage pune-dataset "NAME" ward-name
ask patches [ ifelse is-string? ward-name [] [ set ward-name "Outside" ] ]
gis:set-drawing-color black
gis:draw pune-dataset 1
label-wards
end

to label-wards
  ask admin-labels [die]
  foreach gis:feature-list-of pune-dataset
    [ ?1 -> let centroid gis:location-of gis:centroid-of ?1
       if not empty? centroid
         [create-admin-labels 1
            [ set xcor item 0 centroid
              set ycor item 1 centroid
              set size 0
              set shape "circle"
              set color gray
              let ward_name gis:property-value ?1 "NAME"
              set ward_name upper-case-string ward_name
              set label ward_name
              set label-color black ]
         ]
    ]
end


;;-------------------Initial setup----------------------



to set-global-variables

  set ACTION-RADIUS 0.25
  set HOUSE-SIZE 1
  set HUMAN-SIZE 0.4
  set MOSQUITO-SIZE 0.1
  set BREEDING-ZONE-SIZE 0.5
  set HUMAN-ACTION-RADIUS 30
  set WORKING_HOUR? TRUE
  set HUMAN_KILLING_RANGE 0.25
  set DEATH_BY_HUMAN_PROBABILITY 0.4
  set BREEDING-RANGE 0.5
  set flag 0
  set mylist [0 0]
  set counter 0
  set cnt 0
  set AEDESP-MAX-AGE 40
end

to set-pop

  ;create-people-random
  clear-plot
  reset-ticks
  ask turtles [ die ]
  reset-ticks
  load-pop
  create-aedesp-random
  create-breedingZones-random
  create-houses-random
  create-workZones-random
  move-breedZones-nearhome
  set-house
  ;set-patches
end

;; Check size of all so that movement and ranges mean actually
;;

to create-people-random
  create-people Human_population
  [
    setRandomXY
    set shape "person"
    set color blue
    set age random-integer-between 0  85
    set size HUMAN-SIZE
    set state "Susceptible"
    ifelse random-bool Co-morbid
    [
      set comorbid? False
    ]
    [
      set comorbid? True
    ]
  ]
end

to create-aedesp-random
  create-aedesp Aedes
  [
    setRandomXY
    set age random-integer-between 0 AEDESP-MAX-AGE
    set shape "bug"
    set color white
    set size MOSQUITO-SIZE
    set hunger 0
    set laidEggs? False
    set infected? False

    ifelse (random-bool 0.5)
    [
      set female? True
      if(random-bool 0.01)
    [
      set infected? True
      set color red
    ]
    ]
    [
      set female? False

    ]
  ]
end


to create-breedingZones-random

    create-breedingZones BREED-ZONES
    [
      setRandomXY
      set shape "triangle"
      set color orange
      set size BREEDING-ZONE-SIZE
    ]
end


to create-houses-random
  create-houses counter / 10
  [
    setRandomXY
    set shape "house"
    set color green
    set size HOUSE-SIZE
    move-to one-of patches with [ ward-name != "Outside" ]
  ]
end

to create-workZones-random
  create-workZones 5
  [
    setRandomXY
    set shape "building institution"
    set color yellow
    set size HOUSE-SIZE
  ]
end



to set-patches
  ask patches
  [
    set waterAccumulation 0
  ]
end


to load-pop
  set counter 0
  file-open "Pune_wards1.csv"
    if not file-at-end? [let header csv:from-row file-read-line]
   while [not file-at-end?]
    [let row csv:from-row file-read-line
      ;let district_name item 0 row
      let d_name item 0 row
      let ward_name d_name ;convert text to uppercase
      let district_pop item 1 row
      let small_pop round (district_pop / 1000)
      set counter counter + small_pop
      create-people small_pop
         [
          set ward ward_name
          set shape "person"
          set size HUMAN-SIZE
          set label ""
          set color blue
          move-to one-of patches with [ward-name = [ward] of myself]
          set shape "person"
          set age random-integer-between 0  85
          set size HUMAN-SIZE
          set state "Susceptible"
          ifelse random-bool Co-morbid
          [set comorbid? False ]
          [ set comorbid? True ]
        ]
    ]
    file-close
end


; --initial set up complete

to-report upper-case-string [s]
   ifelse empty? s
   [report ""]
    [ report word (upper-case-char first s)
                  (upper-case-string butfirst s) ]
end

to-report upper-case-char [c]
   let pos position c "abcdefghijklmnopqrstuvwxyz"
   ifelse pos = false
     [ report c ]
     [ report item pos "ABCDEFGHIJKLMNOPQRSTUVWXYZ" ]
end


to infect
  foreach gis:feature-list-of districts
    [ ?1 -> let d_name gis:property-value ?1 "GLOBAL_A_1"
      let infected gis:property-value ?1 "V_ADM2_C_3"
      let sm_infected round infected / 100 ;for visualization
      if sm_infected < 0 [set sm_infected 1]
      if any? people with [district = d_name]
         [ask n-of sm_infected people with [district = d_name]
              [set state "Infected" set color red ]
          ]
    ]
end





;;---------------------human behaviour----------------
to act-humanp
  ask people[
    ;Human daily actions
    ifelse(WORKING_HOUR?)[act-human-day][act-human-night]
  ]
  recovery-or-death-people
end


to act-human-day
  ask people [ rt random 91 - 45 fd 1 ]
end

to act-human-night
  set counter 0
  ask people [go-towards-house my-house 2 0.4]
  ;;show counter
  kill-probabilistically-aedesp
end




;;--------auxillary functions---


to-report random-bool [skew]
  ifelse(random-float 1 > skew)[report false][report true]
end
to-report random-integer-between [minNumber maxNumber]
  report (random (maxNumber - minNumber)) + minNumber
end
to-report transition-age-variation [transition-age deviation]
  report abs (floor (random-normal transition-age deviation))
end
to-report movement-speed-variation [movement-speed deviation]
  report abs (random-normal movement-speed deviation)
end
to setRandomXY
  setxy (random-integer-between (- max-pxcor) max-pxcor) (random-integer-between (- max-pycor) max-pycor)
end

to report-numbers-at-one-stage

  let infected-people (count people with  [state = "Infected"])
  let infected-aedesp (count aedesp with [infected? = True and female? = True])
  let  mylist1 (list infected-people infected-aedesp )
  set mylist lput mylist1 mylist
  if( cnt = 0 )
   [set mylist but-first mylist
    set mylist but-first mylist
    set cnt cnt + 1]
 ;; show mylist
end


;;--------------------mosquito behavioir----------------
to act-aedsp
 ask aedesp
  [
    ;Day and night activities
    ifelse(WORKING_HOUR?)
    [
      act-mosquito-day
    ][
      ifelse(random-bool .2)
      [act-mosquito-day]
      [act-mosquito-night]
    ]
  ]
 ask aedesp[
 set age (age + 1)
 set life_stage_ticks (life_stage_ticks + 1)
 change-state-aedesp
  ]
end

to act-mosquito-day
  ask aedesp [ rt random 91 - 45 fd 1 ]
end

to act-mosquito-night
end


to act-patches
  ask houses
  [
    ask patches in-radius 2
    [
      set waterAccumulation waterAccumulation + 1
      if ( waterAccumulation > 5 and random-bool 0.15 AND SEASON = "Rainy" )
      [
        sprout-breedingZones 1
        [
          set shape "triangle"
          set color orange
          set size 2
        ]

    ]
    ]
  ]
end





to go
  tick
  act-aedsp
  act-humanp
  change-state-aedesp
  aedesp-bite
  reproduce-aedesp
  die-aedesp
  act-patches

  ifelse WORKING_HOUR?
  [set WORKING_HOUR? FALSE]
  [set WORKING_HOUR? TRUE]
  report-numbers-at-one-stage
  eliminate-breeding-zone
  write-to-file
 ;; show count breedingZones
end

;;-------- bite routine
to aedesp-bite
  set flag 0
 ;; show count aedesp with [infected? = True and female? = True and life_stage = "Adult"]
  ask aedesp with [infected? = True and laidEggs? = True and female? = True and hunger < 2]
  [

   ask people in-radius ACTION-RADIUS

    [

      ;;show "people getting infected"
      ;; random-boool is for infection probability
      if (state = "Susceptible" AND (random-bool inf-prob))
       [
        set state "Infected"
        set daysSinceInfection 0
        set flag 1
      ]
    ]
     if (flag = 1 )
      [
        set hunger hunger + 1
        set flag 0
      ]

  ]

  ask aedesp with [infected? = false and life_stage = "Adult" and laidEggs? = True and hunger < 2]
  [
    ;;show "I am here"
    if ( count people with [state = "infected" ] in-radius ACTION-RADIUS <= 1  AND (random-bool inf-prob))
    [
      set infected? True
      set color red
      set hunger hunger + 1
    ]
  ]

end






;;------------------recovery and state change------------
;Changes made here: Check co-morbid status
;Recovery rate of Co-morbid people is considered 0.05 lesser than normal people , this can be turned into variable
;If person does not get recovered within the window then transition to dead will happen.
;; Check number of days > 10 condition- Dead transition is not happening cause of that

to recovery-or-death-people
  ask people with [state = "Infected" or state = "Recovered"]
  [
    set daysSinceInfection daysSinceInfection + 1
    if daysSinceInfection > random-integer-between 7 10 and state = "Infected" AND comorbid? = False AND random-bool Recovery-rate
    [

      set state "Recovered"
    ]
    if daysSinceInfection > random-integer-between 7 10 and state = "Infected" AND comorbid? = True  AND random-bool (Recovery-rate - 0.05)
    [
      set state "Recovered"
    ]
    if (state = "Infected" and daysSinceInfection > 10 )
    [
      show "Death #####"
      set state "Dead"
    ]
    if (daysSinceInfection > 200 and state = "Recovered" )
    [
      set state "Susceptible"
    ]
  ]

end

to lay-eggs
  hatch-aedesp random-integer-between 20 50
  [
    ;show "Inside Hatch"
    set shape "bug"
    set size 0.4
    set age 0
    set life_stage "Eggs"
    ifelse (random-bool 0.5)
    [
      set female? True
      set laidEggs? False
    ]
    [
      set female? False
      set infected? False
      set laidEggs? False
    ]
;   if ( random-bool 0.5 )
  ; [
    ;  show "Inside infected"
     ; set infected? False
    ;]
  ]
end


;;--reproduce Aedesp
; 2 functions written here , temp is not being used
; The actual function consideres whether male is in range and mating can happen also checks for breeding zone in range and if there is no breeding zone in range
; then Vector need to move to Breeding Zone
to reproduce-aedesp-temp
  ask aedesp with [ female? = True and age > 10 and life_Stage = "Adult"]
  [
    if any? aedesp in-radius 2 with [female? = False and life_stage = "Adult"]
    [
    set laidEggs? True
    lay-eggs
    ]
  ]
end


to reproduce-aedesp
  ask aedesp with [ female? = True and age > 10 and life_Stage = "Adult"]
  [
    ifelse ((any? aedesp in-radius 2 with [female? = False and life_stage = "Adult"] ) and ( any? breedingZones in-radius BREEDING-RANGE ) and laidEggs? = False)
    [
    ;;show "I am here"
    set laidEggs? True
    lay-eggs
    ]
    [

      move-towards-breeding-zone (min-one-of breedingZones [distance myself] ) 0.5 0.5
    ]

  ]
end




to change-state-aedesp
  ask aedesp with [age < 4]
  [
    set life_stage "Eggs"
  ]
  ask aedesp with [age >= 4 and age < 8]
  [
    set life_stage "Larva"
  ]
  ask aedesp with [age >= 8 and age <= 10]
  [
    set life_stage "Pupa"
  ]
  ask aedesp with [age > 10]
  [
    set life_stage "Adult"
  ]
end

to die-aedesp
  ask aedesp
  [
    if (age > 40 and random-bool 0.2)
    [
      die
    ]
  ]
end


;; hunger based bite

;; breeding zone simulation

;; Working population


to kill-probabilistically-aedesp
  let aedes_in_range aedesp in-radius HUMAN_KILLING_RANGE
  if(any? aedes_in_range)[if(random-bool 0.1)[ask one-of aedes_in_range[act-dead]]];Death by human
end

to act-dead
  die
end




to move-towards-breeding-zone [target speed probability]
  if(target != nobody)
  [


      let distanceTemp ([distance myself] of target)
      if( ([distance myself] of target) != 0)
      [
        ;;show "Moving towards Breeding zone"
        set heading (towards target)
        ifelse(distanceTemp > speed)[forward speed][forward 1]
      ]

  ]
end



;; Check whether breeding zone is in vicinity of laying eggs - Done
;; Check hunger for bite - Keep hunger Index -- Done
;; Human - Home to Office - to be done today
;; Mathematica reporting
;; Visualization using mathematica
;; Create file for reporting


to eliminate-breeding-zone
  if ( BREED_ZONE_ELM and random-bool 0.2 )
  [
   ask one-of breedingZones
   [
    die
   ]

  ]
end


to go-towards-house [target speed probability ]
   ifelse( random-bool 0.5 )
   [
      set counter counter + 1
      let distanceTemp ([distance myself] of target)
      if( ([distance myself] of target) != 0)
      [
        ;;show "Moving towards Breeding zone"
        set heading (towards target)
        ifelse(distanceTemp > speed)[forward speed][forward distanceTemp]
      ]

   ]

   [
      set heading (random-integer-between 0 180 )

        ;;show "Moving towards Breeding zone"
      forward speed
  ]
end

to set-house
 ask people
  [
     if my-house != nobody [
        set my-house one-of houses
        move-to my-house
  ]
  ]
end


to set-work
  ask people
  [
    if worker? and my-workplace != nobody
    [
      set my-workplace one-of workZones
    ]
  ]
end



to go-towards-work [target speed probability]
  if (random-bool 0.9)
  [
  let distanceTemp ([distance myself] of target)
      if( ([distance myself] of target) != 0)
      [
        ;;show "Moving towards Breeding zone"
        set heading (towards target)
        ifelse(distanceTemp > speed)[forward speed][forward distanceTemp]
      ]
  ]
end

to move-breedZones-nearhome
ask breedingZones[

let target (min-one-of houses [distance myself] )
 let distanceTemp ([ distance myself ] of target )
  if ( distanceTemp > 1 )
  [

    set heading (towards target )
    forward (distanceTemp - 1)
  ]
  ]
end


to write-to-file
    let ph-memory table:from-list mylist
    file-open "/Users/sameergogate/documents/Netlogo_dengue_model/PPPR_project_dengue/testfile.csv"
    file-print csv:to-string table:to-list ph-memory
    file-close
end


;;---------------map and actual population simulation-------- done
;; ---------------addition of exposed state - to be done
;;  have more breeding zones in some wards
@#$#@#$#@
GRAPHICS-WINDOW
210
10
812
613
-1
-1
18.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

SLIDER
904
277
1076
310
Human_population
Human_population
0
10000
2000.0
1
1
NIL
HORIZONTAL

SLIDER
1093
279
1265
312
Aedes
Aedes
0
1000
312.0
1
1
NIL
HORIZONTAL

SWITCH
1289
282
1461
315
Seasonal_variation
Seasonal_variation
1
1
-1000

BUTTON
2
13
68
46
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
2
193
65
226
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
902
109
1102
259
Infected people
Time
Infections
0.0
100.0
0.0
200.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -7500403 true "" "plot count people with  [state = \"Infected\"]"

PLOT
1121
111
1321
261
Infected Vector
NIL
NIL
0.0
100.0
0.0
500.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count aedesp with [infected? = True and female? = True]"

SLIDER
1085
361
1257
394
BREED-ZONES
BREED-ZONES
0
100
48.0
2
1
NIL
HORIZONTAL

SWITCH
871
428
1095
461
BREED_ZONE_ELM
BREED_ZONE_ELM
0
1
-1000

CHOOSER
901
353
1039
398
SEASON
SEASON
"RAINY" "SUMMER" "WINTER"
1

SLIDER
1293
361
1465
394
EGGS-NUMBER
EGGS-NUMBER
10
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
1131
425
1303
458
inf-prob
inf-prob
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
1339
426
1511
459
Recovery-rate
Recovery-rate
0
1
0.995
0.005
1
NIL
HORIZONTAL

SLIDER
895
487
1067
520
Co-morbid
Co-morbid
0
1
0.8
0.05
1
NIL
HORIZONTAL

BUTTON
72
14
135
47
NIL
draw
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
3
56
121
89
NIL
label-wards
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
2
100
83
133
NIL
set-pop
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Dengue_experiments" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-world "test_results.csv"</final>
    <timeLimit steps="50"/>
    <exitCondition>not any? aedesp</exitCondition>
    <metric>count humans with [state = "Infected"]</metric>
    <metric>count aedesp with [infected? = True]</metric>
    <enumeratedValueSet variable="Human_population">
      <value value="1500"/>
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Seasonal_variation">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Aedes">
      <value value="100"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BREED_ZONE_ELM">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SEASON">
      <value value="&quot;SUMMER&quot;"/>
      <value value="&quot;RAINY&quot;"/>
      <value value="&quot;WINTER&quot;"/>
      <value value="&quot;SUMMER&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BREED-ZONES">
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
