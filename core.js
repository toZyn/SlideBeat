export const modes = { flow: { bpm: 100, step: 1, window: .22 }, pulse: { bpm: 128, step: 1, window: .17 }, rush: { bpm: 150, step: .5, window: .13 } };
export function chart(mode) {
  const { bpm, step } = modes[mode];
  const pattern = [0, 3, 1, 2, 0, 1, 3, 2, 1, 0, 2, 3, 0, 2, 1, 3];
  return Array.from({ length: 64 / step }, (_, i) => ({ time: (4 + i * step) * 60 / bpm, dir: pattern[i % pattern.length], done: false }));
}
export function direction(x, y, radius) {
  if (Math.hypot(x, y) < radius) return null;
  return Math.abs(x) > Math.abs(y) ? (x > 0 ? 3 : 2) : (y > 0 ? 1 : 0);
}
export function judge(note, dir, time, window) {
  if (!note || note.done || Math.abs(time - note.time) > window) return null;
  if (note.dir !== dir) return 'miss';
  return Math.abs(time - note.time) <= window * .45 ? 'perfect' : 'good';
}
