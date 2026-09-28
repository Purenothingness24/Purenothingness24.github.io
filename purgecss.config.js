module.exports = {
  content: ["_site/**/*.html", "_site/**/*.js"],
  css: ["_site/assets/css/*.css"],
  output: "_site/assets/css/",
  skippedContentGlobs: ["_site/assets/**/*.html"],
  // Classes that only JavaScript adds, so they never appear in the scanned HTML and JS: Bootstrap builds the
  // popover's placement class (which draws its arrow) at runtime, and medium-zoom comes from a CDN.
  safelist: [/^bs-popover-/, /^medium-zoom-/],
};
