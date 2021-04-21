extensions [matrix]

breed [Macrophages Macrophage]
breed [Fibroblasts Fibroblast]
breed [Viruses Virus]

globals
[
  TNF-baseline
  TGF-baseline
  IL6-baseline
  IL10-baseline
]

turtles-own [life]
Macrophages-own [activation] ;1=activated ;0=deactivated
Viruses-own [clearance]
patches-own [tissue-life
             collagen
             TNF
             TGF
             IL6
             IL10]


; MODEL INITIATION
to setup

  clear-all

  ;set cytokine baselines according to normal distribution N(mean, std)
  set TNF-baseline random-normal TNF-mean-baseline 4.04    ;(Kim et al., 2011)
  set TGF-baseline random-normal TGF-mean-baseline 4.0      ;(Kim et al., 2011)
  set IL6-baseline random-normal IL6-mean-baseline 6.45    ;(Kim et al., 2011)
  set IL10-baseline random-normal IL10-mean-baseline 3.06   ;(Kim et al., 2011)

  ;set to mean-baseline if negative
  if TNF-baseline < 0 [ set TNF-baseline 3.21 ]
  if TGF-baseline < 0 [ set TGF-baseline 3.2 ]
  if IL6-baseline < 0 [ set IL6-baseline 2.91 ]
  if IL10-baseline < 0 [ set IL10-baseline 1.32 ]

  ask patches
  [
    set tissue-life 100 ;heatlhy tissue 100% life
    set collagen collagen-baseline
    set TNF TNF-baseline
    set TGF TGF-baseline
    set IL6 IL6-baseline
    set IL10 IL10-baseline

    set-background
  ]

  set-default-shape Macrophages "circle"
  set-default-shape Fibroblasts "suit diamond"
  set-default-shape Viruses "virus"

  ; create initial macrophages
  create-Macrophages macrophage-baseline + random 2 ;(Lasbury et al., 2003)
  [
    set color white
    set life 2016 + random 3456 ;(Morales-Nebreda et al., 2015)
    set activation 0
    setxy random-xcor random-ycor
  ]

  ;create initial fibroblasts
  create-Fibroblasts 4 + random fibroblast-baseline - 4 ;(Borie et al., 2013)
  [
    set color blue
    set life 2526 + random 468 ;(Weissman-Shomer and Fry, 1975; Itahana et al., 2003)
    setxy random-xcor random-ycor
  ]

  ;expose viruses
  expose

  reset-ticks

end

to expose

  create-Viruses degree-exposure
  [
   set color brown
   set clearance 0
   setxy random-xcor random-ycor
  ]

end


to go

 ask Macrophages
   [Macrophage-function]

 ask Fibroblasts
   [Fibroblast-function]

 ask Viruses
   [Virus-function]

 ask patches
   [
      set-background
   ]

 ask turtles
   [
    set life life - 1
    if life = 0
      [die]
   ]

  ; Macrophage-PROLIFERATION

  let macrophage-interval 60 + random 60
  if ticks mod macrophage-interval = 0
  [
    ;viral particles cause macrophage proliferation
    if (count Viruses > 0) and (count Macrophages < macrophage-baseline * 30)
    [
      let new-macrophages random count Macrophages
      if (count Macrophages + new-macrophages < macrophage-baseline * 30)
      [create-Macrophages new-macrophages
        [
          set color white
          set life 2016 + random 3456
          set activation 0
          setxy random-xcor random-ycor
        ]
      ]
    ]

    ;collagen causes macrophage proliferation
    if (mean [collagen] of patches > collagen-baseline) and (count Macrophages < macrophage-baseline * 30)
    [
      create-Macrophages (mean [collagen] of patches / collagen-baseline) ;ARBITRARY
      [
        set color white
        set life 2016 + random 3456
        set activation 0
        setxy random-xcor random-ycor
      ]
    ]
  ]


  ; Fibroblast-PROLIFERATION

  ;if the mean Anti-inflammatory cytokines of all patches > approx. baseline, # Fibroblasts += mean Anti of all patches
  let fibroblast-interval 60 + random 60
  if ticks mod fibroblast-interval = 0 and ticks < random-normal 5 2 * exposure-time
  [
    let new-fibroblasts random count Fibroblasts
    if  (count Fibroblasts + new-fibroblasts < fibroblast-baseline * 30)
    [
      if (mean [TGF] of patches > (0.99 + random-float 0.01) * TGF-baseline) and (mean [IL10] of patches > (0.99 + random-float 0.01) * IL10-baseline)
      [
        create-Fibroblasts new-fibroblasts
        [
          set color blue
          set life 2526 + random 468
          setxy random-xcor random-ycor
        ]
      ]
    ]
  ]

  ;maintain at least baseline number of macrophages
  if count Macrophages < macrophage-baseline
  [
    create-Macrophages (macrophage-baseline - (count Macrophages) + random 2)
    [
     set color white
     set life 2016 + random 3456
     set activation 0
     setxy random-xcor random-ycor
    ]
  ]

  ;keep at least baseline number of fibroblast
  if count Fibroblasts < fibroblast-baseline
  [
    create-Fibroblasts (fibroblast-baseline - (count Fibroblasts) + random 1)
    [
     set color blue
     set life 2526 + random 468
     setxy random-xcor random-ycor
    ]
  ]


  if (interval > 0) and (ticks < exposure-time)
  [
   if ticks mod interval = 0
     [expose]
  ]

  ; Virus REPLICATION

  let viral-replication-interval 42 + random 6
  if (ticks mod (viral-replication-interval) = 0) and (count Viruses < 1250)
  [
    create-Viruses 2 * random count Viruses
    [
      set color brown
      set clearance 0
      setxy random-xcor random-ycor
    ]
  ]

  diffusion
  degradation

  do-plots

  tick

end


to Macrophage-function

  let cytoPro [TNF] of patch-at 0 0 + [IL6] of patch-at 0 0
  let cytoAnti [TGF] of patch-at 0 0 + [IL10] of patch-at 0 0

  ; Macrophage-ACTIVATION

  ;Macrophages are activated by viral particles
  if (count Viruses-on patch-at 0 0) > 0 or (count Viruses-on patch-ahead 1) > 0 or (count Viruses-on patch-right-and-ahead 45 1) > 0 or (count Viruses-on patch-left-and-ahead 45 1) > 0
      [set activation 1]

  ;Macrophages are also activated by collagen
  if [collagen] of patch 0 0 > collagen-baseline
      [set activation 1]


  ; Macrophage-DEACTIVATION

  ;TOUPDATE: Macrophages are deactivated by TGF (Tsunawaki et al., 1988)
  if ([TGF] of patch-at 0 0 / TGF-baseline) > ([TNF] of patch-at 0 0 / TNF-baseline)
  [if random 100 < [TGF] of patch-at 0 0 ;ARBITRARY prob.
      [set activation 0]
  ]

  ;TOUPDATE: Macrophages are deactivated by IL10 (Bogdan et al., 1991)
  if ([IL10] of patch-at 0 0) > (2 * IL10-baseline)
  [if random 100 < [IL10] of patch-at 0 0 ;ARBITRARY prob.
      [set activation 0]
  ]

  ; Macrophage-MOVEMENT

  let Macro-taxis-left [TNF] of patch-left-and-ahead 45 1 / TNF-baseline + [IL6] of patch-left-and-ahead 45 1 / IL6-baseline + count Viruses-on patch-left-and-ahead 45 1
  let Macro-taxis-right [TNF] of patch-right-and-ahead 45 1 / TNF-baseline + [IL6] of patch-right-and-ahead 45 1 / IL6-baseline + count Viruses-on patch-right-and-ahead 45 1
  let Macro-taxis-ahead [TNF] of patch-ahead 1 + [IL6] of patch-ahead 1 / TNF-baseline + [IL6] of patch-right-and-ahead 45 1 / IL6-baseline + count Viruses-on patch-ahead 1

  (ifelse Macro-taxis-left > Macro-taxis-right
    [
      if Macro-taxis-left > Macro-taxis-ahead
      [lt 45]
    ]
    Macro-taxis-right > Macro-taxis-left
    [
      if Macro-taxis-right > Macro-taxis-ahead
      [rt 45]
    ]
    [
      ;else, move randomly
      rt random 45
      lt random 45
  ])

  fd 1

  ; Macrophage-SECRETION

  secretion

end

to Fibroblast-function

  ;Fibroblast-MOVEMENT

  ;Fibroblasts move towards damaged tissue
  let neighbor-lives [tissue-life] of patches at-points [[0 0] [-1 0] [-1 1] [0 1] [1 1] [1 0] [1 -1] [0 -1] [-1 -1]]
  let pos position min neighbor-lives neighbor-lives ;relative index (integer) of neighbors with min tissue-life
  let indices matrix:from-row-list [[0 0] [-1 0] [-1 1] [0 1] [1 1] [1 0] [1 -1] [0 -1] [-1 -1]]
  setxy [xcor] of self + matrix:get indices pos 0 [ycor] of self + matrix:get indices pos 1

  ;Fibroblasts heal damaged tissue (Jiang et al., 2020)
  ;Fibroblasts deposit collagen (Brown et al., 2011)
  if ([tissue-life] of patch-at 0 0) < 98 and ([collagen] of patch-at 0 0) < 98
  [
    ask patch-at 0 0
    [
        set tissue-life tissue-life + 0.25
        set collagen collagen + 0.5
    ]
  ]


  ; Fibroblast-SECRETION

  ;TGF secretion rate (Ceresa et al., 2018)
  set TGF TGF + (0.04 / 144) * count Macrophages with [activation = 1]

end


to Virus-function

  if clearance = 1
      [set life life - (count Macrophages-on patch-at 0 0)
       if life <= 0
         [die]
      ]

  ; TOUPDATE: set virus life
  if (count Macrophages-on patch-at 0 0) > 0 and clearance = 0
    [set life 100    ;ARBITRARY placeholder
     set clearance 1]

end

to secretion

  ;Activated macrophages produce TNF and TGF inhibits macrophage chemotaxis
  if activation = 1
  [
    ;TGF secretion rate (Ceresa et al., 2018)
    set TGF TGF + (0.07 / 144) * count Macrophages with [activation = 1]

    ;TNF secretion rate (Ceresa et al., 2018)
    set TNF TNF + (0.0007 / 144) * count Macrophages with [activation = 1]

    ;TOUPDATE: IL6 secretion = ?
    set IL6 IL6 + (0.05 / 144) * count Macrophages with [activation = 1]

    ;IL10 secretion rate (Ceresa et al., 2018)
    set IL10 IL10 + (0.0005 / 144) * count Macrophages with [activation = 1]

  ]

end

to diffusion

  ; TOUPDATE: diffusion rates

  diffuse TNF 0.88
  diffuse TGF 0.88
  diffuse IL6 0.88
  diffuse IL10 0.88

end

to degradation

  ask patches
  [

    ;TGF degradation rate (Ceresa et al., 2018)
    if TGF > TGF-baseline
    [set TGF TGF - (15 / 144)]

    ;TNF degradation rate (Ceresa et al., 2018)
    if TNF > TNF-baseline
    [set TNF TNF - (55 / 144)]

    ;TOUPDATE: IL6 degradation rate = ?
    if IL6 > IL6-baseline
    [set IL6 IL6 - (IL6 / IL6-baseline) * (2.5 / 144)]

    ;IL10 degradation rate (Ceresa et al., 2018)
    if IL10 > IL10-baseline
    [set IL10 IL10 - (2.5 / 144)]


    ; TOUPDATE: TNF act as a surrogate for tissue damage
    if (tissue-life > 0) and (TNF > TNF-baseline) and (count Viruses > 0)
    [set tissue-life tissue-life - (random-float 0.30 * TNF / TNF-baseline)]

    ; TOUPDATE: ?
    if (tissue-life > 0) and (IL6 > IL6-baseline) and (count Viruses > 0)
    [set tissue-life tissue-life - (random-float 0.30 * IL6 / IL6-baseline)]

    if tissue-life < 0
    [set tissue-life 0]

    if tissue-life > 100
    [set tissue-life 100]

  ]
end

to set-background

  if mode = "tissue"
  [set pcolor scale-color red  tissue-life 0 255]

  if mode = "collagen"
  [set pcolor scale-color blue collagen 100 0]

  if mode = "TNF"
  [set pcolor scale-color red TNF (TNF-baseline + 4.04) 0]

  if mode = "TGF"
  [set pcolor scale-color green TGF (TGF-baseline + 4.0) 0]

  if mode = "IL6"
  [set pcolor scale-color magenta IL6 (IL6-baseline + 6.45) 0]

  if mode = "IL10"
  [set pcolor scale-color cyan IL10 (IL10-baseline + 1.32) 0]

end


to do-plots

  set-current-plot "Agents"
  set-current-plot-pen "Macro"
  plotxy ticks count Macrophages
  set-current-plot-pen "Fibro"
  plotxy ticks count Fibroblasts
  set-current-plot-pen "Virus"
  plotxy ticks count Viruses

  set-current-plot "Tissue Damage"
  set-current-plot-pen "Collagen"
  plotxy ticks mean [collagen] of patches
  set-current-plot-pen "Tis-life"
  plotxy ticks mean [tissue-life] of patches

  set-current-plot "Cytokines"
  set-current-plot-pen "TNF"
  plotxy ticks mean [TNF] of patches
  set-current-plot-pen "TGF"
  plotxy ticks mean [TGF] of patches
  set-current-plot-pen "IL6"
  plotxy ticks mean [IL6] of patches
  set-current-plot-pen "IL10"
  plotxy ticks mean [IL10] of patches

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
693
494
-1
-1
9.314
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
16
16
82
49
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
100
16
163
49
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

SLIDER
16
63
188
96
degree-exposure
degree-exposure
0
50
10.0
10
1
NIL
HORIZONTAL

SLIDER
16
101
188
134
interval
interval
0
200
50.0
50
1
NIL
HORIZONTAL

SLIDER
16
140
188
173
exposure-time
exposure-time
0
2000
1000.0
100
1
NIL
HORIZONTAL

MONITOR
737
99
807
144
Viruses
count Viruses
3
1
11

MONITOR
827
154
906
199
Tissue Life
mean [tissue-life] of patches
3
1
11

MONITOR
737
217
819
262
Fibroblasts
count Fibroblasts
3
1
11

MONITOR
826
216
915
261
Macrophages
count Macrophages
3
1
11

MONITOR
737
279
818
324
TNF level
mean [TNF] of patches
3
1
11

MONITOR
827
279
913
324
TGF Level
mean [TGF] of patches
3
1
11

MONITOR
737
341
817
386
IL6 level
mean [IL6] of patches
3
1
11

MONITOR
737
156
818
201
Collagen
mean [Collagen] of patches
3
1
11

MONITOR
826
341
912
386
IL10 level
mean [IL10] of patches
3
1
11

PLOT
519
553
727
711
Cytokines
NIL
NIL
0.0
10.0
0.0
7.0
true
true
"" ""
PENS
"TNF" 1.0 0 -2674135 true "" "plot mean [TNF] of patches"
"TGF" 1.0 0 -10899396 true "" "plot mean [TGF] of patches"
"IL6" 1.0 0 -5825686 true "" "plot mean [IL6] of patches"
"IL10" 1.0 0 -11221820 true "" "plot mean [IL10] of patches"

PLOT
262
554
508
711
Tissue Damage
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Collagen" 1.0 0 -10873583 true "plot mean [collagen] of patches" "plot mean [collagen] of patches"
"Tis-life" 1.0 0 -2674135 true "" "plot mean [tissue-life] of patches"

PLOT
17
554
251
711
Agents
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Macro" 1.0 0 -16777216 true "" "plot count Macrophages"
"Fibro" 1.0 0 -13345367 true "" "plot count Fibroblasts"
"Virus" 1.0 0 -6459832 true "" "plot count Viruses"

CHOOSER
736
18
828
63
mode
mode
"tissue" "collagen" "TNF" "TGF" "IL6" "IL10"
1

SLIDER
19
225
190
258
TNF-mean-baseline
TNF-mean-baseline
0
32.1
3.21
0.01
1
NIL
HORIZONTAL

SLIDER
18
265
191
298
TGF-mean-baseline
TGF-mean-baseline
0
32
3.2
0.01
1
NIL
HORIZONTAL

SLIDER
19
305
191
338
IL6-mean-baseline
IL6-mean-baseline
0
29.1
2.91
0.01
1
NIL
HORIZONTAL

SLIDER
18
344
191
377
IL10-mean-baseline
IL10-mean-baseline
0
13.2
1.32
0.01
1
NIL
HORIZONTAL

SLIDER
738
457
911
490
fibroblast-baseline
fibroblast-baseline
1
75
4.0
1
1
NIL
HORIZONTAL

PLOT
388
959
554
1109
IL6
NIL
NIL
2.0
10.0
0.0
2.91
true
false
"" ""
PENS
"IL6" 1.0 0 -5825686 true "" "plot mean [IL6] of patches"

PLOT
209
959
378
1109
TGF
NIL
NIL
2.0
10.0
0.0
3.2
true
false
"" ""
PENS
"TGF" 1.0 0 -10899396 true "" "plot mean [TGF] of patches"

PLOT
23
958
197
1108
TNF
NIL
NIL
2.0
10.0
0.0
3.21
true
false
"" ""
PENS
"TNF" 1.0 0 -2674135 true "" "plot mean [TNF] of patches"

PLOT
564
960
731
1110
IL10
NIL
NIL
2.0
10.0
0.0
1.32
true
false
"" ""
PENS
"IL10" 1.0 0 -11221820 true "" "plot mean [IL10] of patches"

PLOT
23
755
223
905
Macrophage count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Macro" 1.0 0 -16777216 true "" "plot count Macrophages"

PLOT
263
755
463
905
Fibroblast count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Fibro" 1.0 0 -13345367 true "" "plot count Fibroblasts"

PLOT
501
755
701
905
Virus count
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Virus" 1.0 0 -6459832 true "" "plot count Viruses"

SLIDER
17
449
189
482
collagen-baseline
collagen-baseline
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
738
416
912
449
macrophage-baseline
macrophage-baseline
10
100
11.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

In March 2020, the World Health Organization (WHO) declared coronavirus disease 2019 (COVID-19) a pandemic. COVID-19 is caused by the pathogen known as Severe Acute Respiratory Syndrome Coronavirus 2 (SARS-CoV-2). The severity and mortality of COVID-19 is largely attributed to cytokine storm syndrome (Hu, Huang, & Yin, 2021). This first-generation lung injury model is developed to help delineate the  pathophysiological mechanisms of cytokine storm phenomenon in COVID-19.

## HOW IT WORKS

The model consists of lung cells, fibroblasts, and macrophages which undergo proliferation and apoptosis. They also respond to growth factors and cytokines to regulate processes like collagen production which is the basis for fibrosis. The model is exposed to SARS-CoV-2 viruses at time 0.


## HOW TO USE IT

The inputs are to the left of the graphical output view and they can be categorized into exposure regimen, initial cytokine profiles, and starting collagen baseline.

### (1) Define exposure regimen
If the input variable interval is zero, it is a one-time exposure.
Otherwise, interval is the time between each exposure.
degree-exposure is the number of viruses exposed to the environment at every interval.
exposure-time is the total time of exposure.
Together, the three variables define the total viral load exposed.

### (2) Define initial cytokine profiles (optional)
If unadjusted, the default is set to means of healthy serum cytokine levels which is 10% of the maximum values on the sliders (Kim et al., 2011).

### (3) Set starting collagen baseline
You can set the initial collagen baseline from 0-100; the default is 10.


## THINGS TO NOTICE

After you define the input and run the simulations, notice the changes in cytokine profiles. The Tissue Damage shows the average percent of tissue that is viable and the average percent of collagen deposited in the lung tissue.

## THINGS TO TRY

Try selecting different options from the drop down menu to visualize the different attriubtes of the lung environment such as tissue damage, collagen distributions, and the "heat maps" of cytokines TNF, TGF, IL-6, and IL-10.
For tissue mode, the darker the patches are, the less viable the tissue is aka the tissue life is lower.
For collagen, the darker blue indicated more collagen deposited on that patch.
For the cytokine views, the darker color inidicates higher levels of that particular cytokine.
You may also try moving the sliders for macrophage and fibroblast baselines.

## EXTENDING THE MODEL

To further refine the mode, better model parameters are required. In vitro experiments may inform better estimates of rate of change of the parameters.
To extend the current first-generation model, more parameters are required to capture the heterogeneity of the lung tissue and immune cells in vivo.

## NETLOGO FEATURES

While the changes are relatively to baselines, the absolute comparison of a variable to its baseline may not produce the boolean expected. To work around this peculiarity, some stochasticity can be added to the model via NetLogo random sampling algorithms. 

## RELATED MODELS

The agent-based models referenced below may be of interest to study different types of lung injuries.

## CREDITS AND REFERENCES

The author would like to thank Drs. Kristin Miller, Michael Mislove, Mark Mondrinos, and Elvis Danso for their support and contribution. The project was funded by NIH grant #P20GM103629.

Citation for this model source code:
Pwint, MY (2021) COVID-ABM source code (Version 1.0) [Source code]. https://github.com/mpwint/COVID-ABM


### Other References

* Brown, B. N., Price, I. M., Toapanta, F. R., DeAlmeida, D. R., Wiley, C. A., Ross, T. M., . . . Vodovotz, Y. (2011). An agent-based model of inflammation and fibrosis following particulate exposure in the lung. Math Biosci, 231(2), 186-196. doi:10.1016/j.mbs.2011.03.005
* Ceresa, M., Olivares, A. L., Noailly, J., & González Ballester, M. A. (2018). Coupled Immunological and Biomechanical Model of Emphysema Progression. Front Physiol, 9, 388. doi:10.3389/fphys.2018.00388
* Marino, S., & Kirschner, D. E. (2016). A Multi-Compartment Hybrid Computational Model Predicts Key Roles for Dendritic Cells in Tuberculosis Infection. Computation (Basel), 4(4). doi:10.3390/computation4040039
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

circle
false
0
Circle -7500403 true true 0 0 300

suit diamond
true
0
Polygon -7500403 true true 150 15 45 150 150 285 255 150

virus
true
0
Circle -7500403 true true 129 2 42
Circle -7500403 true true 86 86 127
Circle -7500403 true true 129 257 42
Circle -7500403 true true 33 218 42
Circle -7500403 true true 228 217 42
Circle -7500403 true true 223 39 42
Circle -7500403 true true 32 36 42
Circle -7500403 true true 0 127 42
Circle -7500403 true true 255 127 42
Rectangle -7500403 true true 144 37 159 262
Rectangle -7500403 true true 34 139 259 154
Polygon -7500403 true true 62 75 231 231 230 229 242 221 70 63
Polygon -7500403 true true 69 233 69 233 234 77 224 66 60 221
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>export-all-plots (word "experiment" degree-exposure interval ".csv")</final>
    <timeLimit steps="13392"/>
    <metric>count Viruses</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="0"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="50"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="2000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cytokine_sims_severe_n13" repetitions="13" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>let c random 10000
;export-plot "Agents" (word "data/agents/agents_" degree-exposure "viruses_every" interval "s_" c ".csv")
;export-plot "Tissue Damage" (word "data/tissue/tissue_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Cytokines" (word "data/cytokines/cytokines_" degree-exposure "viruses_every" interval "s_" c ".csv")</final>
    <timeLimit steps="5000"/>
    <metric>TNF-baseline</metric>
    <metric>TGF-baseline</metric>
    <metric>IL6-baseline</metric>
    <metric>IL10-baseline</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;tissue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="2000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sims_severe_n13" repetitions="13" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>let c random 10000
export-plot "Agents" (word "data/agents/agents_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Tissue Damage" (word "data/tissue/tissue_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Cytokines" (word "data/cytokines/cytokines_" degree-exposure "viruses_every" interval "s_" c ".csv")</final>
    <timeLimit steps="15000"/>
    <metric>TNF-baseline</metric>
    <metric>TGF-baseline</metric>
    <metric>IL6-baseline</metric>
    <metric>IL10-baseline</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;tissue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="2000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Cytokine_sims_mild_n13" repetitions="13" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>let c random 10000
export-plot "Agents" (word "data/agents/agents_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Tissue Damage" (word "data/tissue/tissue_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Cytokines" (word "data/cytokines/cytokines_" degree-exposure "viruses_every" interval "s_" c ".csv")</final>
    <timeLimit steps="5000"/>
    <metric>TNF-baseline</metric>
    <metric>TGF-baseline</metric>
    <metric>IL6-baseline</metric>
    <metric>IL10-baseline</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;tissue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="2000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Elevated_IL6_severe_n13" repetitions="13" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>let c random 10000
;export-plot "Agents" (word "data/agents/agents_" degree-exposure "viruses_every" interval "s_" c ".csv")
;export-plot "Tissue Damage" (word "data/tissue/tissue_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Cytokines" (word "data/cytokines/ElevatedCytokines_" degree-exposure "viruses_every" interval "s_" c ".csv")</final>
    <timeLimit steps="5000"/>
    <metric>TNF-baseline</metric>
    <metric>TGF-baseline</metric>
    <metric>IL6-baseline</metric>
    <metric>IL10-baseline</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mode">
      <value value="&quot;tissue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="2000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Parametric - viral load" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <final>let c random 9999
export-plot "Agents" (word "data/Virus_parametric/agents/agents_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Tissue Damage" (word "data/Virus_parametric/tissue/tissue_" degree-exposure "viruses_every" interval "s_" c ".csv")
export-plot "Cytokines" (word "data/Virus_parametric/cytokines/cytokines_" degree-exposure "viruses_every" interval "s_" c ".csv")</final>
    <timeLimit steps="15000"/>
    <metric>TNF-baseline</metric>
    <metric>TGF-baseline</metric>
    <metric>IL6-baseline</metric>
    <metric>IL10-baseline</metric>
    <enumeratedValueSet variable="degree-exposure">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interval">
      <value value="0"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exposure-time">
      <value value="1000"/>
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
