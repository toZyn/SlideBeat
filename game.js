import { modes, chart, direction, judge } from './core.js';
const $ = id => document.getElementById(id);
const arrows = [...$('targets').children];
let mode = 'flow', state = 'menu', audio, master, startTime = 0, notes = [], index = 0, score = 0, combo = 0, bestCombo = 0, earned = 0, judged = 0, misses = 0, pointer = null, armed = false, muted = false, duration = 0;
function clock() { return audio.currentTime - startTime; }
function tone(time, frequency, length, volume, type = 'sine') {
  const osc = audio.createOscillator(), gain = audio.createGain();
  osc.type = type; osc.frequency.setValueAtTime(frequency, time);
  gain.gain.setValueAtTime(.0001, time); gain.gain.exponentialRampToValueAtTime(volume, time + .008); gain.gain.exponentialRampToValueAtTime(.0001, time + length);
  osc.connect(gain); gain.connect(master); osc.start(time); osc.stop(time + length + .01);
}
function soundtrack() {
  const beat = 60 / modes[mode].bpm;
  const roots = [130.81, 103.83, 155.56, 116.54];
  for (let b = 0; b < 70; b++) {
    const t = startTime + b * beat, root = roots[Math.floor(b / 8) % 4];
    tone(t, b % 4 === 0 ? 70 : 1000, .08, b % 4 === 0 ? .25 : .035);
    if (b >= 4 && b < 68) {
      tone(t, root / 2, beat * .65, .12, 'triangle');
      tone(t, root * [2, 3, 4, 3][b % 4], beat * .4, .06, 'triangle');
      if (mode === 'rush') tone(t + beat / 2, root * 4, beat * .18, .035);
    }
  }
}
function resetPointer() { pointer = null; armed = false; $('center').classList.remove('armed'); $('trail').setAttribute('d', ''); }
function updateStats() {
  $('score').textContent = String(score).padStart(6, '0');
  $('accuracy').textContent = judged ? `${(earned / judged * 100).toFixed(1)}%` : '—';
}
function result(r) {
  const note = notes[index];
  if (!note) return;
  note.done = true; index++; judged++;
  if (r === 'miss') { combo = 0; misses++; }
  else { combo++; bestCombo = Math.max(combo, bestCombo); earned += r === 'perfect' ? 1 : .65; score += (r === 'perfect' ? 300 : 150) + Math.min(combo, 100) * 5; }
  $('feedback').textContent = r.toUpperCase(); $('combo').textContent = combo ? `${combo} × combo` : 'Find the next beat.';
  updateStats();
}
async function start() {
  state = 'loading'; $('start').disabled = true;
  try {
    if (audio) await audio.close();
    audio = new AudioContext(); master = audio.createGain(); master.gain.value = muted ? 0 : .65; master.connect(audio.destination); await audio.resume();
    notes = chart(mode); index = score = combo = bestCombo = earned = judged = misses = 0;
    duration = 68 * 60 / modes[mode].bpm; startTime = audio.currentTime + .12; soundtrack();
    resetPointer(); updateStats(); state = 'playing'; $('overlay').hidden = true; $('pause').disabled = false; document.body.classList.add('playing'); $('instruction').textContent = 'Hold the center → slide to the lit arrow → return. Keep holding.';
  } catch { state = 'menu'; $('instruction').textContent = 'Audio could not start. Tap Play to try again.'; }
  finally { $('start').disabled = false; }
}
function finish() {
  state = 'results'; resetPointer(); $('pause').disabled = true;
  const accuracy = earned / notes.length * 100;
  let best = 0;
  try { best = Number(localStorage.getItem(`slidebeat-${mode}`)) || 0; if (score > best) localStorage.setItem(`slidebeat-${mode}`, String(score)); } catch {}
  $('overlayTitle').textContent = accuracy >= 95 ? 'In the flow.' : 'Nice session.';
  $('summary').textContent = `${score.toLocaleString()} points · ${accuracy.toFixed(1)}% accuracy\n${bestCombo} best combo · ${misses} misses\nPersonal best: ${Math.max(best, score).toLocaleString()}`;
  $('resume').textContent = 'Play again'; $('overlay').hidden = false;
}
async function pause() {
  if (state !== 'playing') return;
  state = 'paused'; resetPointer(); await audio.suspend(); $('overlayTitle').textContent = 'Take a breath.'; $('summary').textContent = 'Your beat is waiting.'; $('resume').textContent = 'Resume'; $('overlay').hidden = false;
}
async function resume() {
  if (state === 'results') { await start(); return; }
  if (state !== 'paused') return;
  await audio.resume(); state = 'playing'; $('overlay').hidden = true;
}
function position(e) { const box = $('arena').getBoundingClientRect(); return { x: (e.clientX - box.left) / box.width * 500 - 250, y: (e.clientY - box.top) / box.height * 500 - 250 }; }
function move(e) {
  if (state !== 'playing' || e.pointerId !== pointer) return;
  e.preventDefault(); const { x, y } = position(e);
  $('cursor').setAttribute('cx', x + 250); $('cursor').setAttribute('cy', y + 250);
  $('trail').setAttribute('d', `M250 250L${x + 250} ${y + 250}`);
  if (Math.hypot(x, y) <= 42) { armed = true; $('center').classList.add('armed'); return; }
  const dir = direction(x, y, 115);
  if (armed && dir !== null) {
    armed = false; $('center').classList.remove('armed');
    const r = judge(notes[index], dir, clock(), modes[mode].window);
    if (r) result(r); else $('feedback').textContent = 'FOLLOW THE BEAT';
  }
}
$('arena').addEventListener('pointerdown', e => {
  if (state !== 'playing' || pointer !== null || (e.pointerType === 'mouse' && e.button !== 0)) return;
  const { x, y } = position(e); if (Math.hypot(x, y) > 48) return;
  pointer = e.pointerId; $('arena').setPointerCapture(pointer); move(e);
});
$('arena').addEventListener('pointermove', move);
for (const event of ['pointerup', 'pointercancel', 'lostpointercapture']) $('arena').addEventListener(event, e => { if (e.pointerId === pointer) resetPointer(); });
$('arena').addEventListener('contextmenu', e => e.preventDefault());
$('start').onclick = start; $('pause').onclick = pause; $('resume').onclick = resume;
$('exit').onclick = async () => { state = 'menu'; if (audio) await audio.close(); audio = null; resetPointer(); $('overlay').hidden = true; $('pause').disabled = true; document.body.classList.remove('playing'); $('feedback').textContent = 'START IN THE CENTER'; $('combo').textContent = 'Ready when you are.'; };
$('sound').onclick = () => { muted = !muted; if (master && audio?.state !== 'closed') master.gain.value = muted ? 0 : .65; $('sound').textContent = muted ? 'Sound off' : 'Sound on'; $('sound').setAttribute('aria-pressed', String(muted)); };
$('fullscreen').onclick = async () => { try { if (document.fullscreenElement) await document.exitFullscreen(); else await document.documentElement.requestFullscreen(); } catch { $('instruction').textContent = 'Fullscreen is unavailable in this browser.'; } };
document.addEventListener('visibilitychange', () => { if (document.hidden) pause(); });
window.addEventListener('blur', () => pause());
document.addEventListener('keydown', e => { if (e.code === 'Escape' && state === 'playing') pause(); });
for (const button of document.querySelectorAll('[data-mode]')) button.onclick = () => {
  if (state !== 'menu') return;
  mode = button.dataset.mode; document.querySelector('.selected').classList.remove('selected'); button.classList.add('selected'); $('start').firstChild.textContent = `Play ${mode[0].toUpperCase() + mode.slice(1)} `; $('track').textContent = `${mode.toUpperCase()} / ${ { flow: 'SOFT CIRCUIT', pulse: 'AFTER HOURS', rush: 'FAST FORWARD' }[mode]}`;
};
function frame() {
  if (state === 'playing') {
    const time = clock(), window = modes[mode].window;
    while (notes[index] && time > notes[index].time + window) result('miss');
    const note = notes[index], remaining = note ? note.time - time : Infinity;
    arrows.forEach((arrow, dir) => { arrow.classList.toggle('active', !!note && note.dir === dir && remaining < .75); arrow.classList.toggle('next', !!notes[index + 1] && notes[index + 1].dir === dir && remaining < .25); });
    $('approach').style.opacity = remaining < .75 ? '.75' : '0';
    if (note) { const coords = [[250,98],[250,402],[98,250],[402,250]][note.dir]; $('approach').setAttribute('cx',coords[0]); $('approach').setAttribute('cy',coords[1]); $('approach').setAttribute('r', 36 + Math.max(0, Math.min(.75, remaining)) * 65); }
    if (time < notes[0].time - .75) { $('feedback').textContent = `GET READY · ${Math.max(1, Math.ceil((notes[0].time - time) * modes[mode].bpm / 60))}`; }
    $('progress').style.width = `${Math.max(0, Math.min(100, time / duration * 100))}%`;
    const seconds = Math.max(0, Math.floor(time)); $('time').textContent = `${String(Math.floor(seconds / 60)).padStart(2,'0')}:${String(seconds % 60).padStart(2,'0')}`;
    if (time >= duration) finish();
  } else { arrows.forEach(a => a.classList.remove('active', 'next')); $('approach').style.opacity = '0'; }
  requestAnimationFrame(frame);
}
requestAnimationFrame(frame);
