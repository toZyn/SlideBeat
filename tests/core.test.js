import { test } from 'node:test';
import assert from 'node:assert/strict';
import { modes, chart, direction, judge } from '../core.js';
test('charts are ordered, playable, and cover every direction', () => {
  for (const mode of Object.keys(modes)) {
    const notes = chart(mode);
    assert.equal(new Set(notes.map(n => n.dir)).size, 4);
    assert.ok(notes.every((n, i) => !i || n.time > notes[i - 1].time));
    assert.equal(notes.length, mode === 'rush' ? 128 : 64);
  }
});
test('flicks require enough distance and choose the dominant axis', () => {
  assert.equal(direction(0, 0, 115), null);
  assert.equal(direction(10, -150, 115), 0);
  assert.equal(direction(10, 150, 115), 1);
  assert.equal(direction(-150, 10, 115), 2);
  assert.equal(direction(150, 10, 115), 3);
});
test('timing rejects early, late, duplicate and incorrect directions', () => {
  const n = { time: 1, dir: 0, done: false };
  assert.equal(judge(n, 0, 1, .2), 'perfect');
  assert.equal(judge(n, 0, 1.15, .2), 'good');
  assert.equal(judge(n, 1, 1, .2), 'miss');
  assert.equal(judge(n, 0, .7, .2), null);
  assert.equal(judge(n, 0, 1.3, .2), null);
  assert.equal(judge({ ...n, done: true }, 0, 1, .2), null);
});
