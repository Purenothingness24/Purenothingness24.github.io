// Pitch project pages show one slide at a time, and "#n" in the URL picks slide n. Swiping left or right anywhere
// changes slides, like the arrow links. Tapping a video pauses or resumes it (iOS Low Power Mode blocks autoplay
// until then), and dragging a video's progress bar is the only way to scrub.
const slides = [...document.querySelectorAll(".pitch-slide")];

// A clip holds one video: a video slide's player, or a video placed on a rendered slide.
const clipsOf = (root) => [...root.querySelectorAll(".pitch-player, .pitch-clip")];
const videoOf = (clip) => clip.querySelector("video");

const play = (clip) =>
  videoOf(clip)
    .play()
    .catch((error) => {
      // NotAllowedError: autoplay is blocked until a tap. AbortError: a pause or slide change interrupted the start.
      if (error.name !== "NotAllowedError" && error.name !== "AbortError") throw error;
    })
    .then(() => clip.classList.toggle("is-paused", videoOf(clip).paused));

clipsOf(document).forEach((clip) => {
  const video = videoOf(clip);
  const fail = () => reportError(new Error(`Pitch video failed to load: ${video.currentSrc || video.src} (MediaError code ${video.error.code})`));
  if (video.error) fail();
  video.addEventListener("error", fail);
  video.addEventListener("play", () => clip.classList.remove("is-paused"));
  video.addEventListener("pause", () => clip.classList.add("is-paused"));
});

document.querySelectorAll(".pitch-player").forEach((player) => {
  const video = videoOf(player);
  const fit = () => player.style.setProperty("--ratio", `${video.videoWidth} / ${video.videoHeight}`);
  if (video.readyState >= HTMLMediaElement.HAVE_METADATA) fit();
  video.addEventListener("loadedmetadata", fit);
});

// A slide's videos pause and resume together, so one tap restarts every clip on a rendered slide.
slides.forEach((slide) => {
  const clips = clipsOf(slide);
  clips.forEach((clip) =>
    clip.addEventListener("click", () => {
      const resume = clips.some((other) => videoOf(other).paused);
      clips.forEach((other) => (resume ? play(other) : videoOf(other).pause()));
    }),
  );
});

document.querySelectorAll(".pitch-progress").forEach((bar) => {
  const player = bar.closest(".pitch-player");
  const video = videoOf(player);
  const render = () => bar.style.setProperty("--progress", video.duration ? video.currentTime / video.duration : 0);
  let frame = 0;
  const tick = () => {
    render();
    frame = requestAnimationFrame(tick);
  };
  video.addEventListener("play", () => {
    cancelAnimationFrame(frame);
    frame = requestAnimationFrame(tick);
  });
  video.addEventListener("pause", () => {
    cancelAnimationFrame(frame);
    render();
  });
  video.addEventListener("seeked", render);

  // The bar captures the pointer while dragging, and its events stop here so they neither swipe nor pause.
  let resume = false;
  const seek = (event) => {
    const box = bar.getBoundingClientRect();
    video.currentTime = (Math.min(Math.max(event.clientX - box.left, 0), box.width) / box.width) * video.duration;
    render();
  };
  bar.addEventListener("pointerdown", (event) => {
    event.stopPropagation();
    bar.setPointerCapture(event.pointerId);
    bar.classList.add("is-scrubbing");
    resume = !video.paused;
    video.pause();
    seek(event);
  });
  bar.addEventListener("pointermove", (event) => {
    event.stopPropagation();
    if (bar.hasPointerCapture(event.pointerId)) seek(event);
  });
  const release = (event) => {
    event.stopPropagation();
    if (!bar.classList.contains("is-scrubbing")) return;
    bar.classList.remove("is-scrubbing");
    if (resume) play(player);
  };
  bar.addEventListener("pointerup", release);
  bar.addEventListener("pointercancel", release);
  bar.addEventListener("click", (event) => event.stopPropagation());
});

const show = () => {
  let number = location.hash ? Number(location.hash.slice(1)) : 1;
  if (!Number.isInteger(number) || number < 1 || number > slides.length) {
    reportError(new Error(`${location.hash} is not a slide on this page, which has ${slides.length}`));
    number = 1;
  }
  slides.forEach((slide, i) => {
    slide.hidden = i !== number - 1;
    clipsOf(slide).forEach((clip) => {
      if (slide.hidden) {
        videoOf(clip).pause();
      } else {
        videoOf(clip).preload = "auto";
        play(clip);
      }
    });
  });
  if (slides[number]) clipsOf(slides[number]).forEach((clip) => (videoOf(clip).preload = "auto"));
};

const deck = document.querySelector(".pitch-deck");
if (deck) {
  window.addEventListener("hashchange", show);
  // Going back to a page restores it from Safari's page cache with its videos paused.
  window.addEventListener("pageshow", (event) => {
    if (event.persisted) show();
  });
  show();

  let start = null;
  let swipedAt = -Infinity;
  deck.addEventListener("pointerdown", (event) => {
    start = event.isPrimary ? { id: event.pointerId, x: event.clientX, y: event.clientY } : null;
  });
  deck.addEventListener("pointercancel", () => {
    start = null;
  });
  deck.addEventListener("pointerup", (event) => {
    if (!start || event.pointerId !== start.id) return;
    const dx = event.clientX - start.x;
    const dy = event.clientY - start.y;
    start = null;
    if (Math.abs(dx) < 40 || Math.abs(dx) < 1.5 * Math.abs(dy)) return;
    swipedAt = event.timeStamp;
    const link = slides.find((slide) => !slide.hidden).querySelector(dx < 0 ? ".pitch-next" : ".pitch-prev");
    if (link) link.click();
  });
  // A mouse swipe ends in a click on whatever is under the pointer, which must not also pause a video.
  deck.addEventListener(
    "click",
    (event) => {
      if (event.timeStamp - swipedAt < 500 && !event.target.closest("a")) event.stopPropagation();
    },
    true,
  );
}
