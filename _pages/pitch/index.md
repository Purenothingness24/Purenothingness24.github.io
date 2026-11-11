---
# Hidden elevator-pitch deck: reachable by URL only (no `nav`), left out of the sitemap, and marked noindex by
# _layouts/pitch-deck.liquid. Its slides loop (1, 2, 3, 1, ...) and "#n" in the URL opens slide n. A slide either lists
# `projects` or is the `about` slide built from `roles` and `logos`. A project is named by its `bib` entry's title in
# _bibliography/papers.bib up to any colon, or by its `name` if set, and links to that entry's website; its `venue`
# (which may contain Markdown links), `video` and `poster` (under assets/pitch/) are the deck's own.
layout: pitch-deck
permalink: /pitch/
sitemap: false
roles:
  - Visiting Researcher @ FieldAI
  - MS @ CMU Robotics
  - BS @ CMU ECE
logos:
  - file: fieldai.svg
    alt: FieldAI
  - file: cmu.svg
    alt: Carnegie Mellon University
  - file: airlab.png
    alt: CMU AirLab
slides:
  - title: Humanoid Whole-Body Loco-Manipulation
    projects:
      - bib: muscleman
        first_author: true
        venue: CoRL 2026 Workshop
        video: muscleman/muscleman.mp4
        poster: muscleman/poster.jpg
      - bib: retargetingreasoning
        name: Retargeting Through Reasoning
        venue: Project Blog
        video: retargeting/teaser.mp4
        poster: retargeting/poster.jpg
      - bib: propriotrack3r
        venue: In review, 3DV 2027
        video: propriotrack3r/propriotrack3r.mp4
        poster: propriotrack3r/poster.jpg
      - bib: fieldaihumanoid
        name: FieldAI Demos
        venue: '[Singapore HTX](https://www.straitstimes.com/singapore/ai-humanoid-robots-to-be-deployed-with-home-team-officers-by-2028-edwin-tong) & [NVIDIA GTC 2026](https://www.linkedin.com/posts/fieldai_at-nvidia-gtc-this-week-were-announcing-activity-7439413248581337088-mIMZ)'
        video: fieldaihumanoid/fieldai-homepage-hero.mp4
        poster: fieldaihumanoid/poster.jpg
  - title: World Models / Perception
    projects:
      - bib: grndctrl
        first_author: true
        venue: IROS 2026
        video: grndctrl/IROS26_4019_VI_i.mp4
        poster: grndctrl/poster.jpg
      - bib: rayfronts
        venue: IROS 2025
        video: rayfronts/srchvol_teaser.mp4
        poster: rayfronts/poster.jpg
  - about: true
---
