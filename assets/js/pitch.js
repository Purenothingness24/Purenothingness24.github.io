// The pitch deck shows one slide at a time, and "#n" in the URL picks slide n. The slides loop: the arrow links,
// the arrow keys and swiping left or right anywhere step through them in a circle. Tapping a video pauses or
// resumes it (iOS Low Power Mode blocks autoplay until then), and dragging a video's progress bar is the only way to scrub.
// Production builds minify this file with Uglifier (jekyll-minifier), which fails on syntax newer than ES2015 such as ??.
const slides = [...document.querySelectorAll(".pitch-slide")];

const playersOf = (root) => [...root.querySelectorAll(".pitch-player")];
const videoOf = (player) => player.querySelector("video");

const play = (player) =>
  videoOf(player)
    .play()
    .catch((error) => {
      // NotAllowedError: autoplay is blocked until a tap. AbortError: a pause or slide change interrupted the start.
      if (error.name !== "NotAllowedError" && error.name !== "AbortError") throw error;
    })
    .then(() => player.classList.toggle("is-paused", videoOf(player).paused));

playersOf(document).forEach((player) => {
  const video = videoOf(player);
  const slide = player.closest(".pitch-slide");
  const fail = () => reportError(new Error(`Pitch video failed to load: ${video.currentSrc || video.src} (MediaError code ${video.error.code})`));
  if (video.error) fail();
  video.addEventListener("error", fail);
  // Browsers resume the videos they paused while the page was in the background, whatever slide those are on.
  video.addEventListener("play", () => (slide.hidden ? video.pause() : player.classList.remove("is-paused")));
  video.addEventListener("pause", () => player.classList.add("is-paused"));
  player.addEventListener("click", () => (video.paused ? play(player) : video.pause()));
});

document.querySelectorAll(".pitch-progress").forEach((bar) => {
  const player = bar.closest(".pitch-player");
  const video = videoOf(player);
  // The position the finger has dragged to but the video hasn't started seeking to yet. The bar shows it right away.
  let target = null;
  const render = () => bar.style.setProperty("--progress", video.duration ? (target === null ? video.currentTime : target) / video.duration : 0);
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

  // A new seek cancels the one in flight, so seeking on every move would freeze the picture until the finger stops.
  // Instead, each seek starts when the previous one lands, at wherever the finger is by then.
  const seek = () => {
    if (target === null || video.seeking) return;
    video.currentTime = target;
    target = null;
  };
  video.addEventListener("seeked", () => {
    seek();
    render();
  });

  // The bar captures the pointer while dragging, and its events stop here so they neither swipe nor pause.
  let dragging = null;
  let resume = false;
  const positionOf = (event) => {
    const box = bar.getBoundingClientRect();
    return (Math.min(Math.max(event.clientX - box.left, 0), box.width) / box.width) * video.duration;
  };
  const follow = (event) => {
    target = positionOf(event);
    seek();
    render();
  };
  bar.addEventListener("pointerdown", (event) => {
    event.stopPropagation();
    if (dragging !== null || event.button !== 0) return;
    dragging = event.pointerId;
    bar.setPointerCapture(event.pointerId);
    bar.classList.add("is-scrubbing");
    resume = !video.paused;
    video.pause();
    follow(event);
  });
  bar.addEventListener("pointermove", (event) => {
    event.stopPropagation();
    if (event.pointerId === dragging) follow(event);
  });
  // The video ends up where the finger lifts, even if a seek is still in flight.
  const release = (event) => {
    event.stopPropagation();
    if (event.pointerId !== dragging) return;
    dragging = null;
    bar.classList.remove("is-scrubbing");
    if (event.type === "pointerup") target = positionOf(event);
    if (target !== null) {
      video.currentTime = target;
      target = null;
    }
    render();
    if (resume) play(player);
  };
  bar.addEventListener("pointerup", release);
  bar.addEventListener("pointercancel", release);
  bar.addEventListener("lostpointercapture", release);
  bar.addEventListener("click", (event) => event.stopPropagation());
});

const show = () => {
  let number = location.hash ? Number(location.hash.slice(1)) : 1;
  if (!Number.isInteger(number) || number < 1 || number > slides.length) {
    reportError(new Error(`${location.hash} is not a slide in this deck, which has ${slides.length}`));
    number = 1;
  }
  const index = number - 1;
  const active = slides[index];
  slides.forEach((slide) => {
    slide.hidden = slide !== active;
    if (slide.hidden) playersOf(slide).forEach((player) => videoOf(player).pause());
  });
  // The deck loops, so the slides on both sides are one swipe away.
  [index, (index + 1) % slides.length, (index + slides.length - 1) % slides.length].forEach((neighbour) =>
    playersOf(slides[neighbour]).forEach((player) => (videoOf(player).preload = "auto"))
  );
  // Start right away: browsers throttle rendering, so waiting for frames can delay the start by seconds. A browser that
  // refuses a muted video started while it still considers the slide hidden gets a second start once it's laid out.
  playersOf(active).forEach(play);
  requestAnimationFrame(() =>
    requestAnimationFrame(() => {
      if (!active.hidden) playersOf(active).forEach(play);
    })
  );
};

const step = (direction) => slides.find((slide) => !slide.hidden).querySelector(direction > 0 ? ".pitch-next" : ".pitch-prev").click();

const deck = document.querySelector(".pitch-deck");
if (deck) {
  window.addEventListener("hashchange", show);
  // Going back to a page restores it from Safari's page cache with its videos paused.
  window.addEventListener("pageshow", (event) => {
    if (event.persisted) show();
  });
  show();

  document.addEventListener("keydown", (event) => {
    if (event.key === "ArrowRight") step(1);
    if (event.key === "ArrowLeft") step(-1);
  });

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
    step(dx < 0 ? 1 : -1);
  });
  // A mouse swipe ends in a click on whatever is under the pointer, which must not also pause a video.
  deck.addEventListener(
    "click",
    (event) => {
      if (event.timeStamp - swipedAt < 500 && !event.target.closest("a")) event.stopPropagation();
    },
    true
  );
}
