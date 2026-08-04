const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');

const flutterRoot = path.resolve(__dirname, '..', '..', 'flutter');
const catalog = JSON.parse(
  fs.readFileSync(
    path.join(flutterRoot, 'assets', 'catalog', 'exercises_vi.json'),
    'utf8',
  ),
);
const animationSource = fs.readFileSync(
  path.join(flutterRoot, 'assets', '3d', 'exercise_animations.js'),
  'utf8',
);
const viewerSource = fs.readFileSync(
  path.join(flutterRoot, 'assets', '3d', 'model_viewer.html'),
  'utf8',
);

const sandbox = { window: {}, Math };
vm.createContext(sandbox);
vm.runInContext(animationSource, sandbox, {
  filename: 'exercise_animations.js',
});

const animations = sandbox.window.ExerciseAnimations;
const requiredJoints = [
  'head',
  'neck',
  'shoulderL',
  'shoulderR',
  'elbowL',
  'elbowR',
  'wristL',
  'wristR',
  'hipL',
  'hipR',
  'kneeL',
  'kneeR',
  'ankleL',
  'ankleR',
];
const sampleTimes = Array.from({ length: 9 }, (_, index) =>
  (index * Math.PI) / 4,
);

function poseSignature(animationId, time) {
  const joints = animations.getJoints(animationId, time);
  return JSON.stringify({
    joints: requiredJoints.map((key) =>
      joints[key].map((value) => Number(value.toFixed(5))),
    ),
    props: joints.props,
  });
}

test('exercise catalog and renderer expose one explicit animation contract', () => {
  assert.equal(catalog.length, 64);
  assert.ok(animations);
  assert.equal(typeof animations.getJoints, 'function');
  assert.equal(typeof animations.isSupported, 'function');

  const animationIds = catalog.map((exercise) => exercise.animationId);
  assert.ok(
    animationIds.every(
      (animationId) =>
        typeof animationId === 'string' && animationId.length > 0,
    ),
    'Every bundled exercise must declare animationId',
  );
  assert.equal(new Set(animationIds).size, catalog.length);

  const supportedIds = Array.from(animations.supportedAnimationIds).sort();
  assert.deepEqual([...animationIds].sort(), supportedIds);
  assert.equal(animations.isSupported('unknown_exercise'), false);
  assert.equal(animations.getJoints('unknown_exercise', 0), null);
});

test('every bundled animation returns finite joints and observable motion', () => {
  for (const exercise of catalog) {
    const signatures = new Set();

    for (const time of sampleTimes) {
      const joints = animations.getJoints(exercise.animationId, time);
      assert.ok(joints, `${exercise.animationId} must return a pose`);

      for (const key of requiredJoints) {
        assert.equal(
          joints[key]?.length,
          3,
          `${exercise.animationId}.${key} must be a 3D coordinate`,
        );
        assert.ok(
          joints[key].every(Number.isFinite),
          `${exercise.animationId}.${key} must contain finite values`,
        );
      }

      signatures.add(poseSignature(exercise.animationId, time));
    }

    assert.ok(
      signatures.size > 1,
      `${exercise.animationId} must not be a static standing pose`,
    );
  }
});

test('specialized exercises do not regress to unrelated locomotion poses', () => {
  const distinctPairs = [
    ['split_squat', 'bodyweight_squat'],
    ['incline_dumbbell_press', 'brisk_walk'],
    ['reverse_fly', 'brisk_walk'],
    ['jumping_jack', 'treadmill_run'],
    ['low_impact_jumping_jack', 'brisk_walk'],
    ['stationary_bike', 'brisk_walk'],
    ['elliptical', 'brisk_walk'],
    ['assisted_pull_up', 'pull_up'],
    ['conventional_deadlift', 'barbell_romanian_deadlift'],
    ['walking_lunge', 'reverse_lunge'],
  ];

  for (const [left, right] of distinctPairs) {
    assert.notEqual(
      sampleTimes.map((time) => poseSignature(left, time)).join('|'),
      sampleTimes.map((time) => poseSignature(right, time)).join('|'),
      `${left} must not reuse the full ${right} motion`,
    );
  }

  const jumpRope = animations.getJoints('jump_rope', Math.PI / 2);
  assert.ok(jumpRope.props.some((prop) => prop.type === 'rope'));

  const hangingRaise = animations.getJoints(
    'hanging_knee_raise',
    Math.PI / 2,
  );
  assert.ok(hangingRaise.props.some((prop) => prop.type === 'barbell'));
});

test('viewer renders with elapsed time, high-DPI scaling and idle pause', () => {
  assert.match(viewerSource, /devicePixelRatio/);
  assert.match(viewerSource, /elapsedSeconds \* motionRadiansPerSecond/);
  assert.match(viewerSource, /prefers-reduced-motion/);
  assert.match(viewerSource, /if \(isPlaying \|\| isDragging\) requestDraw\(\)/);
  assert.doesNotMatch(viewerSource, /time \+= 0\.05/);
  assert.match(viewerSource, /__IS_DARK_THEME__/);
});
