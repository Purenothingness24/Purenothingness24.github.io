---
# Hidden elevator-pitch deck: reachable by URL only (no `nav`), left out of the sitemap, and marked noindex by
# _layouts/pitch.liquid. Each slug under `groups` is a slide page at /pitch/<slug>/ in this folder.
layout: pitch-home
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
groups:
  - name: Humanoids Loco-Manipulation
    slides: [muscleman, propriotrack3r]
  - name: World Models
    slides: [grndctrl]
  - name: Semantic Scene Exploration
    slides: [rayfronts]
  - name: Deployable Systems
    slides: [fieldaihumanoid, anywill]
---
