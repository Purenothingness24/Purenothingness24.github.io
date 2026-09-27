---
layout: page
permalink: /research/
title: Research
description: ""
nav: true
nav_order: 2
---





{% include bib_search.liquid %}

<div class="publications">

{% bibliography --query @*[category=research]* %}

</div>