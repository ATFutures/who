<!-- Note: this is where I'm adding the write-up for now for maximum visibility.
Can go elsewhere, e.g. as a vignette before this is open sourced. -->
Introduction
------------

Evidence for the effects of motorised transport systems on the economy, the environment, and both human and ecological health has grown rapidly in recent years. In parallel, there is now incontrovertible evidence of health benefits of active travel, especially cycling (Celis-Morales et al. 2017). Such findings have coincided with heavy investment in active travel in some high-income regions, such as the Cycle Superhighways in London, which have been associated with uptake of cycling along busy routes. In most low-income countries, by contrast, investment continues to focus on motorised modes. Furthermore, cars are seen as a status symbol by many in developing nations, leading to rapid motorisation of transport systems in many low-income cities. This has resulted in developing and developed cities moving in opposite directions in terms of active travel.

However, levels of both car ownership and the 'sunk costs' of motorised transport networks are still relatively low in many low-income cities. While the risks of increasing motorisation and associated decreases in levels of physical activity in such cities are high, there is nevertheless a great opportunity to intervene early to 'skip' the phase of heavy motorisation that cities such as London and New York are trying to escape from. This vital transition will require strong and clear evidence of how and where to intervene.

Building on these motivations, this project aims to provide an evidence base that will help local decision makers and investors to direct money spent on cycling infrastructure to where it is most needed and to where it will most be used. The work will build on the Propensity to Cycle Tool (PCT) project (Lovelace et al. 2017). The PCT has become a part of legally binding legislation as part of the UK government's Local Cycling and Walking Infrastructure Plans (LCWIP), process to ensure Local Authorities to invest effectively in active travel.

The project also builds on the team's expertise developing open source software for transport planning. Mark Padgham is the lead developer of both the **osmdata** package for accessing globally available street network data (Padgham et al. 2017), and the **bikedata** package for accessing data from public bicycle hire systems from around the world. Robin Lovelace is the lead developer of the **stplanr** package for transport planning applications with R (Lovelace and Ellison 2017).

This document outlines a methodology for generating a robust evidence base for investing in a strategic cycling network in low-income cities across the world. The methodology will be tested in two cities in urgent need of evidence to inform cycling strategies: Accra (Ghana) and Kathmandu (Nepal).

Input data
==========

The main input dataset will come from OpenStreetMap (OSM), an open access, freely available, crowd-sourced online mapping database. We use this for the following reasons:

-   Coverage: its worldwide coverage ensures that methods developed for one city can be applied to others, reducing the costs of future developments for the WHO and others.
-   Citizen science: OSM empowers citizens to contribute, thereby encouraging a public participation in the planning process and an opening-up of educational opportunities.
-   Resilience: Unlike some datasets which become outdated quickly, OSM is constantly updated and improved, meaning that methods based on OSM data are relatively 'future-proof'.

The arterial, residential, and cycling routes in both cities from OSM are shown in Figure 1, illustrating the citywide coverage of OSM data for both cities.

<img src="../ATF-ideas/who/city-overview-simple.png" alt="Overview of OSM transport network data available in the case study cities generated using the osmdata R package. Grey, black and blue lines represent residential, primary and 'cycleway' roads respectively. Many other transport network features are available from OSM in both cities (not shown)." width="100%" />
<p class="caption">
Overview of OSM transport network data available in the case study cities generated using the osmdata R package. Grey, black and blue lines represent residential, primary and 'cycleway' roads respectively. Many other transport network features are available from OSM in both cities (not shown).
</p>

Additional data on population densities will be obtained from WorldPop and from NASA's Socioeconomic Data and Applications Center (SDAC). The former provides static fine-resolution data (100*m*<sup>2</sup>, for the year 2013 only), while the latter provides coarser (1*k**m*<sup>2</sup>) future projections out to 2020.

Methods
=======

The project will proceed through four methodological phases:

-   Import, characterise and clean the OSM data for each city.

-   Use data on population density and 'trip attractors' (places of employment, shops, hospitals etc) to estimate and forecast the overall transport demand throughout each of the cities at 100*m*<sup>2</sup> resolution; to re-project this travel demand onto the street networks; and from that to estimate cycling potential.

-   Identify locations of potential cycling infrastructure offering the greatest potential benefit in terms of one or more suitable metrics such as potential usage per kilometre, reduction in average optimal cycling journey distances, or estimated health outcomes.

Based on this work a final phase will be implemented to forecast cycling uptake, the details of which depend on the results of the previous two phases. This final phase could provide the basis of health-economic impact estimates

-   Provide scenarios of cycling uptake associated with different levels of investment, from which estimates of (changes in) physical activity and health-economic impacts can be made.

Importantly, rather than providing a set of static recommendations for multiple \`\`optimal'' locations, the third phase will provide a tool able to be iteratively used by local governments to incorporate their own monitoring data and to optimally decide on subsequent investment. Constructing any one cycle way will directly affect the optimal properties and locations of subsequent cycle ways. The tool delivered by this project will enable local governments to dynamically respond to monitored changes in behaviour and to ensure future plans will dynamically adapt to observed changes.

Deliverables, Timeline, and Resource
====================================

The following timings assume a total of 3 person-days per working week from the lead investigators (or equivalent from others at the Universities of Leeds or Salzburg).

Phase 1: Data collection, processing and characterisation of infrastructure
---------------------------------------------------------------------------

**Anticipated Duration:** 2--3 months.

**Description:** This first phase will collect and process data for each city, including data available from open access global repositories such as the aforementioned OSM, WorldPop, and NASA's SDAC, along with any additional local datasets that can be provided by the WHO. Much of the necessary computational infrastructure has already been provided by the aforementioned **osmdata** package.

**Deliverables:** This phase will provide clean datasets and summary information about the 'data landscape' of each case study city. This will relate primarily to population density, trip attractors and transport infrastructure from which to travel patterns will be modelled in the next phase. We will also deliver summaries of the relationships between demographic and transport infrastructure data and an assessment of the quality of local data and priorities for future data collection. The deliverables will be provided in the form of datasets provided to the WHO and interactive and high quality maps.

Phase 2
-------

**Anticipated Duration:** 2--3 months.

**Description:** This phase will estimate current travel patterns and latent demand for cycling. The data collected from Phase 1 will be fed into spatial interaction and network analysis models, to estimate where people currently travel. The models will be cross-validated and refined using "ground truth" data based on international open source datasets or, where available, local data. For all three study locations (Kathmandu, Accra, and Bristol), the data collected in Phase 1 will be allocated to the route network using methods developed for the PCT, as well as with "probabilistic" routing software developed by Mark Padgham and colleagues.

**Deliverables:** This phase will deliver estimated spatial and temporal patterns of flow throughout down to the street network level. Models will be calibrated using "ground truth" data and (where available) local expertise and data. These outputs will be provided as geographic datasets, high resolution maps and reproducible scripts, enabling travel patterns to be updated in the future.

Phase 3
-------

**Anticipated Duration:** 3--4 months.

**Description** The third phase will extend the models of current usage from Phase 2 to provide scenarios of potential uptake, both of cycling behaviour in general and of route usage in particular. This phase moves into uncharted territory in regard to the use of OSM data so this will require a substantial amount of work. These scenarios will be based on current and future population estimates of levels of physical activity and behavioural change, to be fed-into health and health-economic models such as HEAT.

**Deliverables:** This phase will deliver scenarios of cycling uptake for each city, at high geographic resolution and tuned to local parameters. These scenarios will represent different possible futures, ranging from the status quo to 'best cases' in terms of infrastructure and behaviour change (analogous to 'Go Dutch' in the PCT). Models will be represented to the stakeholders as interactive maps and detailed statistical breakdowns, e.g. by socio-economic group, providing a strong basis for evidence-based investment and planning.

Workshops soliciting feedback from local stakeholders and local monitoring data will feed-into the tool's development process as part of an iterative design process. This ongoing adaptation will be particularly important for enabling future extensions of the tool to work in other cities worldwide.

Phase 4
-------

**Anticipated Duration:** 2--4 months (to be completed potentially some time after completion of Phase 3)

**Description:** The final phase will involve estimating the impacts of the various schemes that arise out of Phase 3, focussing on metrics of particular local relevance such as total numbers of trips per year (or other metrics devised through local consultation). The response of these metrics will be related to such factors as individual propensities to cycle, levels of physical activity --- inter-related to other project variables through health-economic models such as HEAT or ITHIM --- topography, climate, and other transport-related factors.

**Deliverables:** This phase will deliver estimated benefits of cycling uptake at high geographic resolution across the case study cities. Scenarios of infrastructure provision and recommendations for strategic cycling plans will also be developed, to maximise the benefits of investment. The phase will also deliver resources that will enable local stakeholders to implement the findings in practice, including an online interactive tool, and an account of how to reproduce or update the recommendation based on new data (e.g. from local monitoring sites or natural experiments).

Next steps
==========

The planning tool delivered at the end of Phase 3 will be able to incorporate a wide range of local data in order to improve the accuracy of understanding and predicting travel behaviour. Phase 4 will demonstrate how such local data and associated local knowledge can be incorporated. Following formal completion of the project, local governments will iteratively repeat the kind of model adaptation and refinement demonstrated in this concluding phase.

Adaptation to purely local conditions is nevertheless likely to entail its own risks, and we would ensure that knowledge gained in also shared across the different local environments. Each additional application of these techniques and the models they generate will enhance the ability of all previous applications to understand factors driving dynamic responses of travel behaviour to changes in infrastructure.

Of particular importance for future syntheses is likely to be the different metrics adopted by each city to capture their best investment in cycling infrastructure. It is likely that parallel recommendations will be developed corresponding to each distinct metric: cycling infrastructure developed to offer the greatest increase in usage per kilometre, or the greatest reduction in aggregate journey distances, or some other metric. Only multiple empirical applications of such distinct metrics will be able to inform an eventual synthesis into a globally applicable set of metrics. This knowledge will ultimately benefit each and every city in which the methodology developed in this project has been applied.

References
==========

<!-- From discussion with Thiago: -->
<!-- In all WHO contracts the work is 'owned' by WHO. -->
<!-- Usually there is an ammendment to the contract that allows it to be published. -->
<!-- WHO requests for it to be open. -->
<!-- In terms timings - they need it by end of Nov but it can delayed. -->
<!-- In Accra there is a linkage with sewage - that will show where there are opportunities for a combined solution where WASH infra and cycle/walking infrastructure could be built at the same time. -->
<!-- APW (agreement) to be sent asap. -->
<!-- Important to have both institutions reflected in the document. -->
<!-- For travel: they pay and provide a stipend for accomodation etc. -->
Celis-Morales, Carlos A, Donald M Lyall, Paul Welsh, Jana Anderson, Lewis Steell, Yibing Guo, Reno Maldonado, et al. 2017. “Association Between Active Commuting and Incident Cardiovascular Disease, Cancer, and Mortality: Prospective Cohort Study.” *BMJ*, April, j1456. doi:[10.1136/bmj.j1456](https://doi.org/10.1136/bmj.j1456).

Lovelace, Robin, and Richard Ellison. 2017. “Stplanr: A Package for Transport Planning.” *Under Review*. <https://github.com/ropensci/stplanr>.

Lovelace, Robin, Anna Goodman, Rachel Aldred, Nikolai Berkoff, Ali Abbas, and James Woodcock. 2017. “The Propensity to Cycle Tool: An Open Source Online System for Sustainable Transport Planning.” *Journal of Transport and Land Use* 10 (1). doi:[10.5198/jtlu.2016.862](https://doi.org/10.5198/jtlu.2016.862).

Padgham, Mark, Robin Lovelace, Maëlle Salmon, and Bob Rudis. 2017. “Osmdata.” *The Journal of Open Source Software* 2 (14). doi:[10.21105/joss.00305](https://doi.org/10.21105/joss.00305).
