<!-- Note: this is where I'm adding the write-up for now for maximum visibility.
Can go elsewhere, e.g. as a vignette before this is open sourced. -->
Introduction
============

There is now incontrovertible evidence of health benefits of active travel, especially cycling (e.g. Celis-Morales et al. 2017). This project aims to provide an evidence base to prioritise investment in cycling.

Input data
==========

Data were accessed from the following sources:

-   Transport network and building data from \***OpenStreetMap (OSM)**, an open access, freely available, crowd-sourced online mapping database.
-   Population density and some demographic data from [worldpop](http://www.worldpop.org.uk/) <!-- - Topographic data from NASA's open SRTM data -->

<!-- Additional data on population densities will be obtained from WorldPop and from NASA's Socioeconomic Data and Applications Center (SDAC). The -->
<!-- former provides static fine-resolution data (100$m^2$, for the year 2013 only), while the latter provides coarser (1$km^2$) future projections -->
<!-- out to 2020. -->
City overviews
==============

This section provides a high-level overview about the geography of each city as it relates to active travel potential. Both cities are included in this section, laying the ground for the next two sections which provide detailed results for Accra and then Kathmandu. Comparing the cities at the outset will help put the results in perspective and lay the foundation for a discussion of how a tool building on this work could be useful to different stakeholders in each city.

An overview of Accra from an active travel perspective
------------------------------------------------------

Monsuru (1 day's work)

-   Institutions working in transport and their aims
-   References about the transport system in Accra
-   Photos of current set-up
-   What is the current modal split?
-   Recent transport policies.
-   How well developed are other infrastructures (e.g. sewerage.)

An overview of Kathmandu from an active travel perspective
----------------------------------------------------------

Results I: Accra
================

Data quality
------------

-   How well is the road network represented on OSM?

<img src="fig/accra-osm-overview.png" alt="Overview of Accra" width="1577" />
<p class="caption">
Overview of Accra
</p>

The aggregated flows for Accra are illustrated below.

<img src="fig/test.png" alt="Aggregated flows for Kathmandu" width="100%" />
<p class="caption">
Aggregated flows for Kathmandu
</p>

We have developed a method for re-allocating the results of the routing algorithm back onto the road network. A custom level of road segmentation was developed to create this geographical aggregated flow map, which clearly shows routes with high cycling potential ([see interactive version](http://rpubs.com/RobinLovelace/341996)):

<img src="fig/accra-flow1-interactive.png" width="1911" />

Results II: Kathmandu
=====================

Data deliverables
=================

Discussion
==========

Policy relevance of results
---------------------------

<!-- To what extent has this deliverable (from phase 1) been delivered? -->
<!-- **Deliverables:** This phase will provide clean datasets and summary information about the 'data landscape' of each case study city. -->
<!-- This will relate primarily to population density, trip attractors and transport infrastructure from which to -->
<!-- We will also deliver summaries of the relationships between demographic and transport infrastructure data and an assessment of the quality of local data and priorities for future data collection. -->
<!-- The deliverables will be provided in the form of datasets provided to the WHO and interactive and high quality maps. -->
The potential uses of an online toolkit
---------------------------------------

Next steps
==========

References
==========

<!-- Anything else to consider here guys? -->
Celis-Morales, Carlos A, Donald M Lyall, Paul Welsh, Jana Anderson, Lewis Steell, Yibing Guo, Reno Maldonado, et al. 2017. “Association Between Active Commuting and Incident Cardiovascular Disease, Cancer, and Mortality: Prospective Cohort Study.” *BMJ*, April, j1456. doi:[10.1136/bmj.j1456](https://doi.org/10.1136/bmj.j1456).
