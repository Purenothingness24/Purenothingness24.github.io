// Play each bib entry's preview clips (from `preview_videos`) one after another, looping back to the first.
// A single clip loops through its own `loop` attribute.
document.querySelectorAll(".preview-videos").forEach((player) => {
  const clips = [...player.querySelectorAll("video")];

  clips.forEach((clip) => {
    const fail = () => reportError(new Error(`Preview video failed to load: ${clip.currentSrc || clip.src} (MediaError code ${clip.error.code})`));
    if (clip.error) fail();
    clip.addEventListener("error", fail);
  });

  if (clips.length === 1) return;

  const preload = (clip) => {
    if (clip.preload !== "auto") {
      clip.preload = "auto";
      clip.load();
    }
  };

  clips.forEach((clip, i) => {
    const next = clips[(i + 1) % clips.length];
    clip.addEventListener("playing", () => {
      clips.forEach((other) => other.classList.toggle("active", other === clip));
      preload(next);
    });
    clip.addEventListener("ended", () => {
      next.currentTime = 0;
      next.play();
    });
  });

  // The first clip autoplays before this deferred script runs, so its first `playing`/`ended` events can be missed.
  preload(clips[1]);
  if (clips[0].ended) clips[1].play();
});
