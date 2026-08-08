// File: exercise_animations.js
// Dynamic 3D Stick-Figure Joint Calculator for every bundled exercise.
// Generates joint coordinates (x, y, z) in meters based on time phase t (0 to 2*PI).

const SUPPORTED_ANIMATION_IDS = Object.freeze([
    'bodyweight_squat', 'goblet_squat', 'barbell_back_squat', 'leg_press',
    'reverse_lunge', 'walking_lunge', 'split_squat', 'step_up',
    'bodyweight_good_morning', 'dumbbell_romanian_deadlift',
    'barbell_romanian_deadlift', 'conventional_deadlift', 'glute_bridge',
    'single_leg_glute_bridge', 'hip_thrust', 'leg_curl', 'leg_extension',
    'standing_calf_raise', 'incline_push_up', 'knee_push_up', 'push_up',
    'dumbbell_bench_press', 'barbell_bench_press', 'incline_dumbbell_press',
    'machine_chest_press', 'cable_fly', 'dumbbell_overhead_press',
    'barbell_overhead_press', 'dumbbell_lateral_raise', 'triceps_pushdown',
    'overhead_triceps_extension', 'prone_y_raise', 'reverse_snow_angel',
    'superman_hold', 'inverted_row', 'one_arm_dumbbell_row',
    'barbell_bent_over_row', 'seated_cable_row', 'lat_pulldown',
    'assisted_pull_up', 'pull_up', 'face_pull', 'reverse_fly',
    'back_extension', 'dumbbell_biceps_curl', 'hammer_curl', 'plank',
    'side_plank', 'dead_bug', 'bird_dog', 'mountain_climber',
    'bicycle_crunch', 'hanging_knee_raise', 'pallof_press', 'brisk_walk',
    'high_knees', 'jumping_jack', 'low_impact_jumping_jack', 'jump_rope',
    'stationary_bike', 'treadmill_walk', 'treadmill_run', 'rowing_machine',
    'elliptical'
]);

const SUPPORTED = new Set(SUPPORTED_ANIMATION_IDS);
const SQUAT = new Set(['bodyweight_squat', 'goblet_squat', 'barbell_back_squat', 'leg_press', 'leg_extension']);
const LUNGE = new Set(['reverse_lunge', 'walking_lunge', 'split_squat', 'step_up']);
const HINGE = new Set(['bodyweight_good_morning', 'dumbbell_romanian_deadlift', 'barbell_romanian_deadlift', 'conventional_deadlift', 'back_extension']);
const POSTERIOR = new Set(['glute_bridge', 'single_leg_glute_bridge', 'hip_thrust', 'leg_curl']);
const PUSH_UP = new Set(['incline_push_up', 'knee_push_up', 'push_up']);
const CHEST = new Set(['dumbbell_bench_press', 'barbell_bench_press', 'incline_dumbbell_press', 'machine_chest_press', 'cable_fly']);
const SHOULDERS_TRICEPS = new Set(['dumbbell_overhead_press', 'barbell_overhead_press', 'dumbbell_lateral_raise', 'triceps_pushdown', 'overhead_triceps_extension']);
const PULL = new Set(['prone_y_raise', 'reverse_snow_angel', 'inverted_row', 'one_arm_dumbbell_row', 'barbell_bent_over_row', 'seated_cable_row', 'lat_pulldown', 'assisted_pull_up', 'pull_up', 'face_pull', 'reverse_fly', 'dumbbell_biceps_curl', 'hammer_curl', 'rowing_machine']);
const CORE_HOLD = new Set(['plank', 'side_plank', 'superman_hold']);
const CORE_OPPOSITE = new Set(['dead_bug', 'bird_dog', 'pallof_press']);
const KNEE_TUCK = new Set(['mountain_climber', 'bicycle_crunch', 'hanging_knee_raise']);
const CARDIO = new Set(['brisk_walk', 'high_knees', 'jumping_jack', 'low_impact_jumping_jack', 'jump_rope', 'stationary_bike', 'treadmill_walk', 'treadmill_run', 'elliptical']);

window.ExerciseAnimations = {
    supportedAnimationIds: SUPPORTED_ANIMATION_IDS,
    isSupported: function(animationId) {
        return SUPPORTED.has(animationId);
    },

    // Helper to calculate joint coordinates for a specific exercise and phase t
    getJoints: function(exerciseId, t) {
        if (!SUPPORTED.has(exerciseId)) return null;

        // Base standing skeleton template
        const joints = {
            head: [0, 1.65, 0],
            neck: [0, 1.5, 0],
            shoulderL: [-0.2, 1.42, 0],
            shoulderR: [0.2, 1.42, 0],
            elbowL: [-0.22, 1.15, 0],
            elbowR: [0.22, 1.15, 0],
            wristL: [-0.22, 0.88, 0],
            wristR: [0.22, 0.88, 0],
            hipL: [-0.15, 0.82, 0],
            hipR: [0.15, 0.82, 0],
            kneeL: [-0.15, 0.45, 0],
            kneeR: [0.15, 0.45, 0],
            ankleL: [-0.15, 0.05, 0],
            ankleR: [0.15, 0.05, 0],
            props: [] // Holds equipment rendering details: e.g. barbell, dumbbells
        };

        // Determine general phase (0 = stand/start, 1 = bottom/max extension)
        const phase = 0.5 - 0.5 * Math.cos(t);

        // Group exercises by movement patterns
        if (SQUAT.has(exerciseId)) {
            // --- SQUAT PATTERN ---
            const s = phase; // Squat depth (0 to 1)
            
            if (exerciseId === "leg_extension") {
                // Seated, legs extension
                // Hips fixed
                joints.hipL = [-0.15, 0.6, 0.2];
                joints.hipR = [0.15, 0.6, 0.2];
                joints.kneeL = [-0.15, 0.58, 0.5];
                joints.kneeR = [0.15, 0.58, 0.5];
                
                // Ankles swing up
                const extAngle = s * Math.PI / 2.2; // 0 to 90 degrees approx
                joints.ankleL = [-0.15, 0.58 - 0.45 * Math.cos(extAngle), 0.5 + 0.45 * Math.sin(extAngle)];
                joints.ankleR = [0.15, 0.58 - 0.45 * Math.cos(extAngle), 0.5 + 0.45 * Math.sin(extAngle)];
                
                // Torso seated back
                joints.neck = [0, 1.1, -0.1];
                joints.head = [0, 1.25, -0.08];
                joints.shoulderL = [-0.2, 1.05, -0.08];
                joints.shoulderR = [0.2, 1.05, -0.08];
                joints.elbowL = [-0.25, 0.75, 0];
                joints.elbowR = [0.25, 0.75, 0];
                joints.wristL = [-0.25, 0.68, 0.1];
                joints.wristR = [0.25, 0.68, 0.1];
            } else if (exerciseId === "leg_press") {
                // Seated press
                joints.neck = [0, 0.65, -0.4];
                joints.head = [0, 0.8, -0.38];
                joints.shoulderL = [-0.2, 0.62, -0.38];
                joints.shoulderR = [0.2, 0.62, -0.38];
                joints.hipL = [-0.15, 0.35, -0.1];
                joints.hipR = [0.15, 0.35, -0.1];
                joints.elbowL = [-0.28, 0.42, -0.2];
                joints.elbowR = [0.28, 0.42, -0.2];
                joints.wristL = [-0.28, 0.38, -0.1];
                joints.wristR = [0.28, 0.38, -0.1];
                
                // Feet/Ankles push away
                const feetZ = 0.3 + 0.4 * s;
                const feetY = 0.4 + 0.2 * s;
                joints.ankleL = [-0.15, feetY, feetZ];
                joints.ankleR = [0.15, feetY, feetZ];
                
                // Knees bend to the sides
                joints.kneeL = [-0.3, 0.45 - 0.15 * s, 0.1 + 0.1 * s];
                joints.kneeR = [0.3, 0.45 - 0.15 * s, 0.1 + 0.1 * s];
            } else {
                // Standing Squat (Goblet, Barbell, Bodyweight)
                const squatDepth = 0.55 * s;
                
                joints.ankleL = [-0.18, 0.05, 0];
                joints.ankleR = [0.18, 0.05, 0];
                
                // Hips move down and back
                joints.hipL = [-0.15, 0.82 - squatDepth, -0.32 * s];
                joints.hipR = [0.15, 0.82 - squatDepth, -0.32 * s];
                
                // Knees move forward
                joints.kneeL = [-0.18, 0.45 - squatDepth * 0.5, 0.22 * s];
                joints.kneeR = [0.18, 0.45 - squatDepth * 0.5, 0.22 * s];
                
                // Spine angles forward slightly
                joints.neck = [0, 1.5 - squatDepth * 0.95, -0.18 * s];
                joints.head = [0, 1.65 - squatDepth * 0.95, -0.15 * s];
                joints.shoulderL = [-0.2, 1.42 - squatDepth * 0.95, -0.18 * s];
                joints.shoulderR = [0.2, 1.42 - squatDepth * 0.95, -0.18 * s];
                
                if (exerciseId === "bodyweight_squat") {
                    // Tay xoay tu buong thong (dung) sang duoi thang truoc (ngoi sau)
                    // de giu thang bang. Truoc day elbow/wrist deu dat z = 0.3*s / 0.55*s
                    // tai cung mot do cao, nen o s=0 ba khop vai/khuyu/co tay trung
                    // nhau va canh tay bien mat khi render.
                    const armAngle = s * Math.PI / 2;   // 0 = thong xuong, PI/2 = ngang truoc
                    const upperArm = 0.27;
                    const foreArm = 0.27;
                    const shY = 1.42 - squatDepth * 0.95;
                    const shZ = -0.18 * s;
                    const dirY = -Math.cos(armAngle);
                    const dirZ = Math.sin(armAngle);
                    const elY = shY + upperArm * dirY;
                    const elZ = shZ + upperArm * dirZ;
                    joints.elbowL = [-0.2, elY, elZ];
                    joints.elbowR = [0.2, elY, elZ];
                    joints.wristL = [-0.2, elY + foreArm * dirY, elZ + foreArm * dirZ];
                    joints.wristR = [0.2, elY + foreArm * dirY, elZ + foreArm * dirZ];
                } else if (exerciseId === "goblet_squat") {
                    // Hold dumbbell at chest
                    joints.elbowL = [-0.15, 1.15 - squatDepth, 0.15 - 0.1 * s];
                    joints.elbowR = [0.15, 1.15 - squatDepth, 0.15 - 0.1 * s];
                    joints.wristL = [-0.08, 1.25 - squatDepth, 0.2 - 0.1 * s];
                    joints.wristR = [0.08, 1.25 - squatDepth, 0.2 - 0.1 * s];
                    
                    // Add Goblet Dumbbell prop
                    joints.props.push({
                        type: 'dumbbell',
                        pos: [0, 1.25 - squatDepth, 0.22 - 0.1 * s],
                        rot: [0, 0, 0],
                        size: 0.18
                    });
                } else if (exerciseId === "barbell_back_squat") {
                    // Hold barbell behind neck
                    joints.elbowL = [-0.32, 1.25 - squatDepth * 0.95, -0.18 * s - 0.1];
                    joints.elbowR = [0.32, 1.25 - squatDepth * 0.95, -0.18 * s - 0.1];
                    joints.wristL = [-0.35, 1.42 - squatDepth * 0.95, -0.18 * s - 0.05];
                    joints.wristR = [0.35, 1.42 - squatDepth * 0.95, -0.18 * s - 0.05];
                    
                    // Barbell across shoulders
                    joints.props.push({
                        type: 'barbell',
                        pos: [0, 1.44 - squatDepth * 0.95, -0.18 * s - 0.05],
                        rot: [0, 0, 0],
                        length: 1.6
                    });
                }
            }
        } 
        else if (LUNGE.has(exerciseId)) {
            // --- LUNGE / STEP-UP PATTERN ---
            const s = phase;
            
            if (exerciseId === "step_up") {
                // Step up onto a bench/box
                // Bench rendering prop
                joints.props.push({
                    type: 'box',
                    pos: [0, 0.22, 0.35],
                    size: [0.4, 0.44, 0.4]
                });
                
                // Standing leg (ankle fixed)
                joints.ankleR = [0.15, 0.05, 0];
                
                // Active leg steps up
                joints.ankleL = [-0.15, 0.05 + 0.44 * s, 0.1 + 0.25 * s];
                
                // Hips rise and move forward
                joints.hipL = [-0.15, 0.82 + 0.4 * s, 0.25 * s];
                joints.hipR = [0.15, 0.82 + 0.4 * s, 0.25 * s];
                
                // Goi giai bang IK cho ca hai chan (truoc day cang tay/dui co
                // gian khi buoc len buc).
                for (const side of ['L', 'R']) {
                    const hip = joints['hip' + side];
                    const ank = joints['ankle' + side];
                    const vy = ank[1] - hip[1], vz = ank[2] - hip[2];
                    const raw = Math.hypot(vy, vz) || 1e-4;
                    const uy = vy / raw, uz = vz / raw;
                    const dist = Math.min(raw, 0.75 * 0.995);
                    const a = (dist * dist + 0.37 * 0.37 - 0.38 * 0.38) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, 0.37 * 0.37 - a * a));
                    joints['knee' + side] = [
                        side === 'L' ? -0.15 : 0.15,
                        hip[1] + uy * a + uz * h,
                        hip[2] + uz * a - uy * h
                    ];
                }

                joints.neck = [0, 1.5 + 0.4 * s, 0.25 * s];
                joints.head = [0, 1.65 + 0.4 * s, 0.25 * s];
                joints.shoulderL = [-0.2, 1.42 + 0.4 * s, 0.25 * s];
                joints.shoulderR = [0.2, 1.42 + 0.4 * s, 0.25 * s];
                
                // Arms pump
                joints.wristL = [-0.25, 0.88 + 0.4 * s, 0.25 * s - 0.1 + 0.2 * s];
                joints.wristR = [0.25, 0.88 + 0.4 * s, 0.25 * s + 0.1 - 0.2 * s];
                // Khuyu noi tiep giua vai va co tay: truoc day giu mac dinh nen
                // canh tay tren co gian 0.18 -> 0.37 khi than nguoi nang len.
                for (const side of ['L', 'R']) {
                    const sh = joints['shoulder' + side];
                    const w = joints['wrist' + side];
                    const vy = w[1] - sh[1], vz = w[2] - sh[2];
                    const raw = Math.hypot(vy, vz) || 1e-4;
                    const uy = vy / raw, uz = vz / raw;
                    const dist = Math.min(raw, 0.53 * 0.995);
                    const a = (dist * dist + 0.27 * 0.27 - 0.26 * 0.26) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, 0.27 * 0.27 - a * a));
                    const sgn = side === 'L' ? -1 : 1;
                    joints['elbow' + side] = [
                        (side === 'L' ? -0.22 : 0.22) + 0.04 * sgn,
                        sh[1] + uy * a - uz * h,
                        sh[2] + uz * a + uy * h
                    ];
                }
            } else {
                // Lunge variants keep their own stance instead of sharing a squat pose.
                const isSplit = exerciseId === "split_squat";
                const isWalking = exerciseId === "walking_lunge";
                const travel = isWalking ? 0.22 * Math.sin(t) : 0;
                const rearZ = isSplit ? -0.42 : 0.2 - 0.65 * s;
                joints.ankleL = [-0.15, 0.05, 0.25 + travel];
                joints.ankleR = [0.15, 0.05, rearZ + travel];
                
                // Hip drops
                joints.hipL = [-0.15, 0.82 - 0.42 * s, travel];
                joints.hipR = [0.15, 0.82 - 0.42 * s, travel];
                
                // Knees bend
                joints.kneeL = [-0.15, 0.45 - 0.2 * s, 0.28 + travel];
                // Goi sau giai bang IK: truoc day dat toa do rieng nen dui phai
                // co gian 0.43 -> 0.53 khi chan sau duoi ra.
                {
                    const hip = joints.hipR, ank = joints.ankleR;
                    const vy = ank[1] - hip[1], vz = ank[2] - hip[2];
                    const raw = Math.hypot(vy, vz) || 1e-4;
                    const uy = vy / raw, uz = vz / raw;
                    let dist = Math.min(raw, 0.75 * 0.995);
                    const a = (dist * dist + 0.37 * 0.37 - 0.38 * 0.38) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, 0.37 * 0.37 - a * a));
                    joints.kneeR = [0.15, hip[1] + uy * a + uz * h, hip[2] + uz * a - uy * h];
                }
                
                joints.neck = [0, 1.5 - 0.42 * s, travel - 0.05 * s];
                joints.head = [0, 1.65 - 0.42 * s, travel - 0.05 * s];
                joints.shoulderL = [-0.2, 1.42 - 0.42 * s, travel - 0.05 * s];
                joints.shoulderR = [0.2, 1.42 - 0.42 * s, travel - 0.05 * s];

                if (isWalking) {
                    joints.elbowL = [-0.22, 1.15 - 0.3 * s, travel - 0.18 * Math.sin(t)];
                    joints.elbowR = [0.22, 1.15 - 0.3 * s, travel + 0.18 * Math.sin(t)];
                    joints.wristL = [-0.22, 0.9 - 0.2 * s, travel - 0.28 * Math.sin(t)];
                    joints.wristR = [0.22, 0.9 - 0.2 * s, travel + 0.28 * Math.sin(t)];
                }
            }
        }
        else if (HINGE.has(exerciseId)) {
            // --- HINGE / BENT OVER PATTERN ---
            const s = phase; // hinge amount (0 to 1)
            
            if (exerciseId === "back_extension") {
                // Seated/angled bench back extension
                joints.props.push({
                    type: 'line',
                    start: [0, 0.8, -0.2],
                    end: [0, 0.05, -0.2],
                    color: '#6B7280'
                });
                
                // Hips fixed
                joints.hipL = [-0.15, 0.8, -0.1];
                joints.hipR = [0.15, 0.8, -0.1];
                joints.ankleL = [-0.15, 0.2, -0.2];
                joints.ankleR = [0.15, 0.2, -0.2];
                joints.kneeL = [-0.15, 0.5, -0.15];
                joints.kneeR = [0.15, 0.5, -0.15];
                
                // Torso folds down
                const angle = s * Math.PI / 3; // up to 60 degrees down
                joints.neck = [0, 0.8 + 0.7 * Math.cos(angle), 0.7 * Math.sin(angle)];
                joints.head = [0, 0.8 + 0.85 * Math.cos(angle), 0.85 * Math.sin(angle)];
                joints.shoulderL = [-0.2, 0.8 + 0.65 * Math.cos(angle), 0.65 * Math.sin(angle)];
                joints.shoulderR = [0.2, 0.8 + 0.65 * Math.cos(angle), 0.65 * Math.sin(angle)];
                
                // Hands crossed on chest
                joints.elbowL = [-0.15, 0.8 + 0.55 * Math.cos(angle), 0.55 * Math.sin(angle) + 0.15];
                joints.elbowR = [0.15, 0.8 + 0.55 * Math.cos(angle), 0.55 * Math.sin(angle) + 0.15];
                joints.wristL = [0.08, 0.8 + 0.62 * Math.cos(angle), 0.62 * Math.sin(angle) + 0.05];
                joints.wristR = [-0.08, 0.8 + 0.62 * Math.cos(angle), 0.62 * Math.sin(angle) + 0.05];
            } else {
                // Standing Hinge (Deadlift, Good Morning, RDL)
                const isConventional = exerciseId === "conventional_deadlift";
                const hingeAngle = s * Math.PI / (isConventional ? 3.4 : 4.2);
                
                // Ankles fixed
                joints.ankleL = [-0.15, 0.05, 0];
                joints.ankleR = [0.15, 0.05, 0];
                
                // Knees soften slightly
                joints.kneeL = [-0.15, 0.45 - (isConventional ? 0.18 : 0.02) * s, (isConventional ? 0.13 : -0.05) * s];
                joints.kneeR = [0.15, 0.45 - (isConventional ? 0.18 : 0.02) * s, (isConventional ? 0.13 : -0.05) * s];
                
                // Hips push backward
                const hipZ = -(isConventional ? 0.14 : 0.22) * s;
                const hipY = 0.82 - (isConventional ? 0.3 : 0.12) * s;
                joints.hipL = [-0.15, hipY, hipZ];
                joints.hipR = [0.15, hipY, hipZ];
                
                // Torso hinges forward
                const cosA = Math.cos(hingeAngle);
                const sinA = Math.sin(hingeAngle);
                // Shoulder & Neck locations
                const torsoLen = 0.6;
                joints.neck = [0, hipY + torsoLen * cosA, hipZ + torsoLen * sinA];
                joints.head = [0, hipY + (torsoLen + 0.15) * cosA, hipZ + (torsoLen + 0.15) * sinA];
                joints.shoulderL = [-0.2, hipY + torsoLen * cosA, hipZ + torsoLen * sinA];
                joints.shoulderR = [0.2, hipY + torsoLen * cosA, hipZ + torsoLen * sinA];
                
                if (exerciseId.includes("good_morning")) {
                    // Hands behind head
                    joints.elbowL = [-0.28, joints.head[1] - 0.05, joints.head[2] + 0.08];
                    joints.elbowR = [0.28, joints.head[1] - 0.05, joints.head[2] + 0.08];
                    joints.wristL = [-0.08, joints.head[1], joints.head[2] - 0.05];
                    joints.wristR = [0.08, joints.head[1], joints.head[2] - 0.05];
                } else {
                    // Deadlift / RDL - Arms hang straight down (z matches shoulders)
                    const armLen = 0.55;
                    joints.elbowL = [-0.22, joints.shoulderL[1] - armLen * 0.5, joints.shoulderL[2]];
                    joints.elbowR = [0.22, joints.shoulderR[1] - armLen * 0.5, joints.shoulderR[2]];
                    joints.wristL = [-0.22, joints.shoulderL[1] - armLen, joints.shoulderL[2]];
                    joints.wristR = [0.22, joints.shoulderR[1] - armLen, joints.shoulderR[2]];
                    
                    if (exerciseId.includes("dumbbell")) {
                        // Dumbbells prop
                        joints.props.push({
                            type: 'dumbbell',
                            pos: joints.wristL,
                            rot: [0.2, 0, 0],
                            size: 0.18
                        });
                        joints.props.push({
                            type: 'dumbbell',
                            pos: joints.wristR,
                            rot: [0.2, 0, 0],
                            size: 0.18
                        });
                    } else {
                        // Barbell prop
                        const barY = joints.wristL[1];
                        const barZ = joints.wristL[2];
                        joints.props.push({
                            type: 'barbell',
                            pos: [0, barY, barZ],
                            rot: [0, 0, 0],
                            length: 1.4
                        });
                    }
                }
            }
        }
        else if (POSTERIOR.has(exerciseId)) {
            // --- LIE ON BACK / BENCH THRUST PATTERN ---
            const s = phase;
            
            if (exerciseId === "leg_curl") {
                // Lying leg curl (lying on front)
                joints.head = [0, 0.4, 0.7];
                joints.neck = [0, 0.35, 0.55];
                joints.shoulderL = [-0.2, 0.32, 0.52];
                joints.shoulderR = [0.2, 0.32, 0.52];
                joints.elbowL = [-0.22, 0.15, 0.6];
                joints.elbowR = [0.22, 0.15, 0.6];
                joints.wristL = [-0.15, 0.12, 0.7];
                joints.wristR = [0.15, 0.12, 0.7];
                
                // Lying flat hips
                joints.hipL = [-0.15, 0.18, 0.1];
                joints.hipR = [0.15, 0.18, 0.1];
                joints.kneeL = [-0.15, 0.15, -0.3];
                joints.kneeR = [0.15, 0.15, -0.3];
                
                // Ankles curl up
                const curlAngle = s * Math.PI / 1.8; // up to 100 degrees
                joints.ankleL = [-0.15, 0.15 + 0.4 * Math.sin(curlAngle), -0.3 + 0.4 * Math.cos(curlAngle)];
                joints.ankleR = [0.15, 0.15 + 0.4 * Math.sin(curlAngle), -0.3 + 0.4 * Math.cos(curlAngle)];
                
                // Bench support line
                joints.props.push({
                    type: 'line',
                    start: [0, 0.15, 0.55],
                    end: [0, 0.12, -0.35],
                    color: '#6B7280',
                    width: 3
                });
            } else if (exerciseId === "hip_thrust") {
                // Back on bench, hips drive up
                // Bench rendering
                joints.props.push({
                    type: 'box',
                    pos: [0, 0.4, -0.35],
                    size: [0.6, 0.45, 0.25]
                });
                
                // Ankles fixed on floor
                joints.ankleL = [-0.2, 0.05, 0.35];
                joints.ankleR = [0.2, 0.05, 0.35];
                
                // Hips rise from bottom to flat
                const hipY = 0.25 + 0.32 * s;
                const hipZ = -0.15 + 0.08 * s;
                joints.hipL = [-0.15, hipY, hipZ];
                joints.hipR = [0.15, hipY, hipZ];
                
                // Knees
                joints.kneeL = [-0.18, 0.45 + 0.12 * s, 0.3];
                joints.kneeR = [0.18, 0.45 + 0.12 * s, 0.3];
                
                // Upper back stays on bench
                joints.neck = [0, 0.56, -0.32];
                joints.head = [0, 0.62, -0.32];
                joints.shoulderL = [-0.2, 0.54, -0.32];
                joints.shoulderR = [0.2, 0.54, -0.32];
                
                // Arms support
                joints.elbowL = [-0.22, 0.35, -0.22];
                joints.elbowR = [0.22, 0.35, -0.22];
                joints.wristL = [-0.15, 0.45, 0];
                joints.wristR = [0.15, 0.45, 0];
                
                if (exerciseId.includes("barbell")) {
                    joints.props.push({
                        type: 'barbell',
                        pos: [0, hipY + 0.08, hipZ + 0.05],
                        rot: [0, 0, 0],
                        length: 1.3
                    });
                }
            } else {
                // Glute Bridge - Lying flat on floor
                // Feet flat
                joints.ankleL = [-0.18, 0.05, 0.3];
                joints.ankleR = [0.18, 0.05, 0.3];
                
                // Knees bent
                joints.kneeL = [-0.18, 0.42, 0.22];
                joints.kneeR = [0.18, 0.42, 0.22];
                
                // Hips lift
                const hipY = 0.08 + 0.35 * s;
                const hipZ = -0.05 + 0.05 * s;
                joints.hipL = [-0.15, hipY, hipZ];
                joints.hipR = [0.15, hipY, hipZ];
                
                // Shoulders & Head flat
                joints.neck = [0, 0.08, -0.4];
                joints.head = [0, 0.08, -0.55];
                joints.shoulderL = [-0.2, 0.08, -0.4];
                joints.shoulderR = [0.2, 0.08, -0.4];
                joints.elbowL = [-0.25, 0.05, -0.2];
                joints.elbowR = [0.25, 0.05, -0.2];
                joints.wristL = [-0.25, 0.05, 0];
                joints.wristR = [0.25, 0.05, 0];
                
                if (exerciseId === "single_leg_glute_bridge") {
                    // Left leg extends up in the air
                    joints.kneeL = [-0.18, 0.42 + 0.35 * s, 0.22 - 0.1 * s];
                    joints.ankleL = [-0.18, 0.65 + 0.5 * s, 0.35 - 0.2 * s];
                }
            }
        }
        else if (exerciseId === "standing_calf_raise") {
            const lift = 0.09 * phase;
            joints.ankleL = [-0.15, 0.05 + lift, -0.04 * phase];
            joints.ankleR = [0.15, 0.05 + lift, -0.04 * phase];
            for (const jointName of ['kneeL', 'kneeR', 'hipL', 'hipR', 'shoulderL', 'shoulderR', 'neck', 'head', 'elbowL', 'elbowR', 'wristL', 'wristR']) {
                joints[jointName][1] += lift;
            }
            joints.props.push({
                type: 'line',
                start: [-0.28, 0.03, 0.08],
                end: [0.28, 0.03, 0.08],
                color: '#9CA3AF',
                width: 3
            });
        }
        else if (PUSH_UP.has(exerciseId)) {
            // --- PUSH UP PATTERN ---
            const s = phase;
            const pushDepth = 0.28 * s;
            
            // Core body line is inclined. Hands fixed on floor/bench.
            let handsY = 0.05;
            let feetY = 0.05;
            
            if (exerciseId === "incline_push_up") {
                handsY = 0.45; // Hands on bench
                joints.props.push({
                    type: 'box',
                    pos: [0, 0.22, 0.45],
                    size: [0.6, 0.45, 0.25]
                });
            }
            
            // Ankles / Feet support
            joints.ankleL = [-0.15, feetY, -0.7];
            joints.ankleR = [0.15, feetY, -0.7];
            joints.kneeL = [-0.15, feetY + 0.1, -0.45];
            joints.kneeR = [0.15, feetY + 0.1, -0.45];
            
            if (exerciseId === "knee_push_up") {
                // Pivot at knees
                joints.kneeL = [-0.15, 0.05, -0.3];
                joints.kneeR = [0.15, 0.05, -0.3];
                joints.ankleL = [-0.15, 0.22, -0.5];
                joints.ankleR = [0.15, 0.22, -0.5];
            }
            
            // Body line angles down from head/neck to feet/knees
            const pivotY = (exerciseId === "knee_push_up") ? 0.05 : feetY;
            const pivotZ = (exerciseId === "knee_push_up") ? -0.3 : -0.7;
            
            // Hips
            const hipY = pivotY + 0.35 - pushDepth * 0.8;
            joints.hipL = [-0.15, hipY, pivotZ + 0.35];
            joints.hipR = [0.15, hipY, pivotZ + 0.35];
            
            // Shoulders move down
            const shY = pivotY + 0.65 - pushDepth;
            const shZ = pivotZ + 0.72;
            joints.shoulderL = [-0.28, shY, shZ];
            joints.shoulderR = [0.28, shY, shZ];
            joints.neck = [0, shY, shZ];
            joints.head = [0, shY + 0.06, shZ + 0.15];
            
            // Hands fixed
            joints.wristL = [-0.3, handsY, pivotZ + 0.72];
            joints.wristR = [0.3, handsY, pivotZ + 0.72];

            // Khuyu nam GIUA vai va ban tay, banh ra ngoai va ha thap dan khi
            // ha nguoi. Truoc day dat tai shY + 0.1 (cao hon ca vai) trong khi
            // ban tay chong san o y = 0.05, nen cang tay dai 0.77m (chuan 0.24)
            // va khuyu chia nguoc len tren.
            const puMix = 0.5;
            const puFlare = 0.16 - 0.04 * s;
            const puElbowY = shY + (handsY - shY) * puMix;
            const puElbowZ = shZ + ((pivotZ + 0.72) - shZ) * puMix - 0.1 * (1 - s);
            joints.elbowL = [-0.3 - puFlare, puElbowY, puElbowZ];
            joints.elbowR = [0.3 + puFlare, puElbowY, puElbowZ];
        }
        else if (CHEST.has(exerciseId)) {
            // --- BENCH PRESS / FLY PATTERN ---
            const s = phase;
            const isIncline = exerciseId === "incline_dumbbell_press";
            const isMachine = exerciseId === "machine_chest_press";

            if (isMachine) {
                joints.hipL = [-0.15, 0.58, -0.12];
                joints.hipR = [0.15, 0.58, -0.12];
                joints.neck = [0, 1.28, -0.18];
                joints.head = [0, 1.43, -0.18];
                joints.shoulderL = [-0.24, 1.2, -0.15];
                joints.shoulderR = [0.24, 1.2, -0.15];
                joints.kneeL = [-0.2, 0.55, 0.32];
                joints.kneeR = [0.2, 0.55, 0.32];
                joints.ankleL = [-0.2, 0.05, 0.38];
                joints.ankleR = [0.2, 0.05, 0.38];
                joints.props.push({ type: 'box', pos: [0, 0.3, -0.12], size: [0.48, 0.55, 0.5] });
                joints.props.push({ type: 'line', start: [0, 0.55, -0.28], end: [0, 1.32, -0.28], color: '#6B7280', width: 5 });
            } else {
                const inclineY = isIncline ? 0.3 : 0;
                const inclineZ = isIncline ? 0.18 : 0;
                joints.neck = [0, 0.45 + inclineY, -0.2 - inclineZ];
                joints.head = [0, 0.45 + inclineY + 0.08, -0.35 - inclineZ];
                joints.shoulderL = [-0.25, 0.45 + inclineY, -0.2 - inclineZ];
                joints.shoulderR = [0.25, 0.45 + inclineY, -0.2 - inclineZ];
                joints.hipL = [-0.15, 0.45, 0.3];
                joints.hipR = [0.15, 0.45, 0.3];
                joints.ankleL = [-0.3, 0.05, 0.3];
                joints.ankleR = [0.3, 0.05, 0.3];
                joints.kneeL = [-0.3, 0.42, 0.3];
                joints.kneeR = [0.3, 0.42, 0.3];
                joints.props.push({
                    type: 'box',
                    pos: [0, 0.22, 0.05],
                    size: [0.4, 0.45, 0.95]
                });
                if (isIncline) {
                    joints.props.push({ type: 'line', start: [0, 0.4, 0.18], end: [0, 0.78, -0.38], color: '#6B7280', width: 6 });
                }
            }
            
            if (exerciseId === "cable_fly") {
                // Arms wide arc khép mở
                const armAngle = (1 - s) * Math.PI / 3; // 0 to 60 deg wide
                const r = 0.5; // arm radius
                joints.elbowL = [-0.25 - r * Math.cos(armAngle), 0.45 + r * Math.sin(armAngle) * 0.3, -0.2 + r * Math.sin(armAngle) * 0.7];
                joints.elbowR = [0.25 + r * Math.cos(armAngle), 0.45 + r * Math.sin(armAngle) * 0.3, -0.2 + r * Math.sin(armAngle) * 0.7];
                joints.wristL = [-0.25 - 0.8 * Math.cos(armAngle), 0.45 + 0.8 * Math.sin(armAngle) * 0.3, -0.2 + 0.8 * Math.sin(armAngle) * 0.7];
                joints.wristR = [0.25 + 0.8 * Math.cos(armAngle), 0.45 + 0.8 * Math.sin(armAngle) * 0.3, -0.2 + 0.8 * Math.sin(armAngle) * 0.7];
            } else if (isMachine) {
                const pressZ = 0.48 * s;
                joints.wristL = [-0.25, 1.18, 0.08 + pressZ];
                joints.wristR = [0.25, 1.18, 0.08 + pressZ];
                joints.elbowL = [-0.38 + 0.12 * s, 1.08, -0.02 + pressZ * 0.55];
                joints.elbowR = [0.38 - 0.12 * s, 1.08, -0.02 + pressZ * 0.55];
                joints.props.push({ type: 'line', start: joints.wristL, end: [-0.5, 1.18, -0.15], color: '#9CA3AF', width: 3 });
                joints.props.push({ type: 'line', start: joints.wristR, end: [0.5, 1.18, -0.15], color: '#9CA3AF', width: 3 });
            } else {
                // Press pattern - vertical pushing up
                const pressHeight = 0.38 * s;
                const inclineLift = isIncline ? 0.3 : 0;
                const inclineReach = isIncline ? 0.18 * s : 0;
                joints.wristL = [-0.26, 0.48 + inclineLift + pressHeight, -0.2 + inclineReach];
                joints.wristR = [0.26, 0.48 + inclineLift + pressHeight, -0.2 + inclineReach];
                
                // Elbows go down/wide
                joints.elbowL = [-0.38 + 0.12 * s, 0.38 + inclineLift + pressHeight * 0.4, -0.2 + inclineReach * 0.5];
                joints.elbowR = [0.38 - 0.12 * s, 0.38 + inclineLift + pressHeight * 0.4, -0.2 + inclineReach * 0.5];
                
                if (exerciseId.includes("barbell")) {
                    joints.props.push({
                        type: 'barbell',
                        pos: [0, 0.48 + pressHeight, -0.2],
                        rot: [0, 0, 0],
                        length: 1.3
                    });
                } else {
                    // Dumbbells
                    joints.props.push({
                        type: 'dumbbell',
                        pos: joints.wristL,
                        rot: [0, 0, 0],
                        size: 0.18
                    });
                    joints.props.push({
                        type: 'dumbbell',
                        pos: joints.wristR,
                        rot: [0, 0, 0],
                        size: 0.18
                    });
                }
            }
        }
        else if (SHOULDERS_TRICEPS.has(exerciseId)) {
            // --- VERTICAL PUSH / SHOULDERS / ARMS PATTERN ---
            const s = phase;
            
            // Standing core
            joints.ankleL = [-0.15, 0.05, 0];
            joints.ankleR = [0.15, 0.05, 0];
            
            if (exerciseId.includes("overhead_press")) {
                // Press upwards
                const pushY = 0.55 * s;
                joints.wristL = [-0.22, 1.4 + pushY, 0.05 * s];
                joints.wristR = [0.22, 1.4 + pushY, 0.05 * s];
                
                // Elbows tuck under
                joints.elbowL = [-0.28 + 0.08 * s, 1.15 + pushY * 0.6, 0.05 * s];
                joints.elbowR = [0.28 - 0.08 * s, 1.15 + pushY * 0.6, 0.05 * s];
                
                if (exerciseId.includes("barbell")) {
                    joints.props.push({
                        type: 'barbell',
                        pos: [0, 1.4 + pushY, 0.05 * s],
                        rot: [0, 0, 0],
                        length: 1.3
                    });
                } else {
                    joints.props.push({
                        type: 'dumbbell',
                        pos: joints.wristL,
                        rot: [0, 0, 0],
                        size: 0.18
                    });
                    joints.props.push({
                        type: 'dumbbell',
                        pos: joints.wristR,
                        rot: [0, 0, 0],
                        size: 0.18
                    });
                }
            } else if (exerciseId.includes("lateral_raise")) {
                // Raise hands to sides
                const ang = s * Math.PI / 2.3; // almost 90 deg
                const cosA = Math.cos(ang);
                const sinA = Math.sin(ang);
                const armL = 0.5;
                
                joints.elbowL = [joints.shoulderL[0] - armL * cosA, joints.shoulderL[1] + armL * sinA, 0];
                joints.elbowR = [joints.shoulderR[0] + armL * cosA, joints.shoulderR[1] + armL * sinA, 0];
                joints.wristL = [joints.shoulderL[0] - 0.8 * cosA, joints.shoulderL[1] + 0.8 * sinA, 0];
                joints.wristR = [joints.shoulderR[0] + 0.8 * cosA, joints.shoulderR[1] + 0.8 * sinA, 0];
                
                joints.props.push({
                    type: 'dumbbell',
                    pos: joints.wristL,
                    rot: [0, 0, 0],
                    size: 0.16
                });
                joints.props.push({
                    type: 'dumbbell',
                    pos: joints.wristR,
                    rot: [0, 0, 0],
                    size: 0.16
                });
            } else if (exerciseId === "triceps_pushdown") {
                // Cable pushdown. Upper arms fixed. Elbows bend.
                joints.elbowL = [-0.2, 1.15, 0.1];
                joints.elbowR = [0.2, 1.15, 0.1];
                
                // Wrists swing down
                const pushAng = s * Math.PI / 2.5; // up to ~70 degrees down
                const cosP = Math.cos(pushAng);
                const sinP = Math.sin(pushAng);
                
                joints.wristL = [-0.18, 1.15 - 0.35 * cosP, 0.1 + 0.35 * sinP];
                joints.wristR = [0.18, 1.15 - 0.35 * cosP, 0.1 + 0.35 * sinP];
                
                // Cable line
                joints.props.push({
                    type: 'line',
                    start: [0, 1.9, 0.35],
                    end: [0, 1.15 - 0.35 * cosP, 0.1 + 0.35 * sinP],
                    color: '#9CA3AF'
                });
            } else if (exerciseId === "overhead_triceps_extension") {
                // Dumbbell overhead extension
                joints.elbowL = [-0.12, 1.75, 0.15];
                joints.elbowR = [0.12, 1.75, 0.15];
                
                // Hands extend straight up
                const extAng = s * Math.PI / 2.2;
                const cosE = Math.cos(extAng);
                const sinE = Math.sin(extAng);
                
                // At s=0 (start), hands are behind neck/head (z=-0.1, y=1.55)
                // At s=1 (ext), hands are straight up (z=0.15, y=1.95)
                joints.wristL = [-0.08, 1.55 + 0.42 * sinE, 0.15 - 0.25 * cosE];
                joints.wristR = [0.08, 1.55 + 0.42 * sinE, 0.15 - 0.25 * cosE];
                
                joints.props.push({
                    type: 'dumbbell',
                    pos: [0, 1.55 + 0.42 * sinE, 0.15 - 0.25 * cosE],
                    rot: [0, 0, 1.57],
                    size: 0.18
                });
            }
        }
        else if (PULL.has(exerciseId)) {
            // --- PULL PATTERN ---
            const s = phase;
            
            if (exerciseId === "pull_up" || exerciseId === "assisted_pull_up") {
                // Hanging from a bar
                joints.props.push({
                    type: 'barbell', // Use barbell as bar
                    pos: [0, 1.9, 0],
                    rot: [0, 0, 0],
                    length: 1.2
                });
                
                // Hands fixed on bar
                joints.wristL = [-0.35, 1.9, 0];
                joints.wristR = [0.35, 1.9, 0];
                
                // Body pulls up
                const pullY = 0.45 * s;
                joints.head = [0, 1.6 + pullY, 0];
                joints.neck = [0, 1.45 + pullY, 0];
                joints.shoulderL = [-0.25, 1.38 + pullY, 0];
                joints.shoulderR = [0.25, 1.38 + pullY, 0];
                
                joints.elbowL = [-0.38, 1.6 + pullY * 0.3, 0];
                joints.elbowR = [0.38, 1.6 + pullY * 0.3, 0];
                
                // Hips and legs hang, knees bend back slightly
                joints.hipL = [-0.15, 0.8 + pullY, 0];
                joints.hipR = [0.15, 0.8 + pullY, 0];
                joints.kneeL = [-0.15, 0.4 + pullY, -0.15 * s];
                joints.kneeR = [0.15, 0.4 + pullY, -0.15 * s];
                joints.ankleL = [-0.15, 0.05 + pullY, -0.22 * s];
                joints.ankleR = [0.15, 0.05 + pullY, -0.22 * s];
                if (exerciseId === "assisted_pull_up") {
                    joints.kneeL = [-0.15, 0.5 + pullY, 0.16];
                    joints.kneeR = [0.15, 0.5 + pullY, 0.16];
                    joints.ankleL = [-0.15, 0.28 + pullY, 0.08];
                    joints.ankleR = [0.15, 0.28 + pullY, 0.08];
                    joints.props.push({
                        type: 'line',
                        start: [0, 1.9, 0],
                        end: [0, 0.52 + pullY, 0.16],
                        color: '#22C55E',
                        width: 4
                    });
                }
            } else if (exerciseId === "lat_pulldown") {
                // Seated pulling bar down
                joints.hipL = [-0.15, 0.6, 0];
                joints.hipR = [0.15, 0.6, 0];
                joints.kneeL = [-0.18, 0.62, 0.35];
                joints.kneeR = [0.18, 0.62, 0.35];
                joints.ankleL = [-0.18, 0.15, 0.35];
                joints.ankleR = [0.18, 0.15, 0.35];
                
                joints.neck = [0, 1.25, -0.05];
                joints.head = [0, 1.4, -0.03];
                joints.shoulderL = [-0.22, 1.22, -0.05];
                joints.shoulderR = [0.22, 1.22, -0.05];
                
                // Seat rendering
                joints.props.push({
                    type: 'box',
                    pos: [0, 0.3, 0.1],
                    size: [0.4, 0.5, 0.5]
                });
                
                // Bar pulls down from 1.9m to 1.3m
                const barY = 1.95 - 0.65 * s;
                // Tay nam rong hon vai mot chut (0.30 so voi vai 0.22): rong hon
                // nua thi khoang cach vai->co tay vuot tam voi cua canh tay
                // (0.28 + 0.24) va xuong buoc phai gian ra de noi duoc.
                const lpGrip = 0.30;
                joints.wristL = [-lpGrip, barY, 0.05 * s];
                joints.wristR = [lpGrip, barY, 0.05 * s];
                // Khuyu nam GIUA vai va co tay, hoi banh ra ngoai. Truoc day dat
                // tai barY + 0.25 tuc CAO HON ca thanh don, khien canh tay tren
                // dai toi 1.00m (chuan 0.28) va khuyu gap nguoc len tren.
                const lpShY = 1.22;
                const lpElbowBulge = 0.10 + 0.05 * s;
                joints.elbowL = [
                    -lpGrip - lpElbowBulge,
                    lpShY + (barY - lpShY) * 0.5,
                    -0.04 * s
                ];
                joints.elbowR = [
                    lpGrip + lpElbowBulge,
                    lpShY + (barY - lpShY) * 0.5,
                    -0.04 * s
                ];
                
                joints.props.push({
                    type: 'barbell',
                    pos: [0, barY, 0.05 * s],
                    rot: [0, 0, 0],
                    length: 1.1
                });
            } else if (exerciseId === "rowing_machine") {
                // Seated row machine sliding
                const slide = 0.45 * (1 - s);
                joints.hipL = [-0.15, 0.35, -0.3 + slide];
                joints.hipR = [0.15, 0.35, -0.3 + slide];
                joints.neck = [0, 0.95, -0.35 + slide - 0.1 * s];
                joints.head = [0, 1.1, -0.33 + slide - 0.1 * s];
                joints.shoulderL = [-0.2, 0.92, -0.35 + slide - 0.1 * s];
                joints.shoulderR = [0.2, 0.92, -0.35 + slide - 0.1 * s];
                
                // Foot rest fixed
                joints.ankleL = [-0.15, 0.3, 0.4];
                joints.ankleR = [0.15, 0.3, 0.4];
                // Knees flatten as we slide back
                joints.kneeL = [-0.15, 0.35 + 0.3 * (1 - slide), 0.1 + 0.15 * (1 - slide)];
                joints.kneeR = [0.15, 0.35 + 0.3 * (1 - slide), 0.1 + 0.15 * (1 - slide)];
                
                // Pull handle
                const handleZ = 0.45 - 0.55 * s;
                const handleY = 0.7 - 0.1 * s;
                joints.wristL = [-0.15, handleY, handleZ + slide];
                joints.wristR = [0.15, handleY, handleZ + slide];
                // Khuyu noi tiep giua vai va tay nam, banh nhe ra ngoai khi keo
                // ve. Truoc day dat toa do doc lap nen canh tay tren dai 0.83m
                // (chuan 0.28) luc tay con vuon xa.
                const rmShY = 0.92;
                const rmShZ = -0.35 + slide - 0.1 * s;
                const rmMix = 0.5;
                const rmBulge = 0.10 + 0.10 * s;
                joints.elbowL = [
                    -0.15 - rmBulge,
                    rmShY + (handleY - rmShY) * rmMix,
                    rmShZ + ((handleZ + slide) - rmShZ) * rmMix
                ];
                joints.elbowR = [
                    0.15 + rmBulge,
                    rmShY + (handleY - rmShY) * rmMix,
                    rmShZ + ((handleZ + slide) - rmShZ) * rmMix
                ];
            } else if (exerciseId === "barbell_bent_over_row" || exerciseId === "one_arm_dumbbell_row" || exerciseId === "inverted_row" || exerciseId === "seated_cable_row") {
                // Standing / Seated Rows
                if (exerciseId === "seated_cable_row") {
                    joints.hipL = [-0.15, 0.3, 0];
                    joints.hipR = [0.15, 0.3, 0];
                    joints.ankleL = [-0.15, 0.32, 0.55];
                    joints.ankleR = [0.15, 0.32, 0.55];
                    joints.kneeL = [-0.15, 0.4, 0.3];
                    joints.kneeR = [0.15, 0.4, 0.3];
                    
                    joints.neck = [0, 0.95, -0.1 - 0.1 * s];
                    joints.head = [0, 1.1, -0.08 - 0.1 * s];
                    joints.shoulderL = [-0.2, 0.92, -0.1 - 0.1 * s];
                    joints.shoulderR = [0.2, 0.92, -0.1 - 0.1 * s];
                    
                    // Pull rope/bar
                    const handleZ = 0.5 - 0.55 * s;
                    joints.wristL = [-0.12, 0.75, handleZ];
                    joints.wristR = [0.12, 0.75, handleZ];
                    // Khuyu noi tiep giua vai va tay nam. Truoc day co dinh tai
                    // z = handleZ - 0.15*s trong khi vai o z = -0.1 - 0.1*s, nen
                    // luc tay vuon xa (handleZ = 0.5) canh tay tren dai 0.64m.
                    const scrShY = 0.92;
                    const scrShZ = -0.1 - 0.1 * s;
                    const scrMix = 0.5;
                    const scrBulge = 0.12 + 0.08 * s;
                    joints.elbowL = [
                        -0.12 - scrBulge,
                        scrShY + (0.75 - scrShY) * scrMix,
                        scrShZ + (handleZ - scrShZ) * scrMix
                    ];
                    joints.elbowR = [
                        0.12 + scrBulge,
                        scrShY + (0.75 - scrShY) * scrMix,
                        scrShZ + (handleZ - scrShZ) * scrMix
                    ];
                } else if (exerciseId === "inverted_row") {
                    // Lying suspended
                    joints.ankleL = [-0.15, 0.05, 0.7];
                    joints.ankleR = [0.15, 0.05, 0.7];
                    
                    // Bar above chest
                    joints.props.push({
                        type: 'barbell',
                        pos: [0, 0.95, 0],
                        rot: [0, 0, 0],
                        length: 1.1
                    });
                    
                    // Hands fixed on bar
                    joints.wristL = [-0.3, 0.95, 0];
                    joints.wristR = [0.3, 0.95, 0];
                    
                    // Body pulls up to the bar
                    const pullY = 0.15 + 0.65 * s;
                    joints.head = [0, pullY + 0.75, -0.55];
                    joints.neck = [0, pullY + 0.6, -0.4];
                    joints.shoulderL = [-0.25, pullY + 0.55, -0.4];
                    joints.shoulderR = [0.25, pullY + 0.55, -0.4];
                    joints.hipL = [-0.15, pullY + 0.25, 0.15];
                    joints.hipR = [0.15, pullY + 0.25, 0.15];
                    joints.kneeL = [-0.15, pullY * 0.5 + 0.12, 0.42];
                    joints.kneeR = [0.15, pullY * 0.5 + 0.12, 0.42];
                    
                    joints.elbowL = [-0.38, pullY + 0.25 * (1 - s), -0.15 * s];
                    joints.elbowR = [0.38, pullY + 0.25 * (1 - s), -0.15 * s];
                } else {
                    // Standing Bent Over Rows
                    joints.ankleL = [-0.15, 0.05, 0];
                    joints.ankleR = [0.15, 0.05, 0];
                    joints.kneeL = [-0.15, 0.4, 0.05];
                    joints.kneeR = [0.15, 0.4, 0.05];
                    joints.hipL = [-0.15, 0.75, -0.18];
                    joints.hipR = [0.15, 0.75, -0.18];
                    
                    // Torso bent forward
                    joints.neck = [0, 1.15, 0.25];
                    joints.head = [0, 1.28, 0.35];
                    joints.shoulderL = [-0.2, 1.12, 0.25];
                    joints.shoulderR = [0.2, 1.12, 0.25];
                    
                    // Pull tạ
                    const pullY = 0.38 * s;
                    const pullZ = 0.12 * s;
                    joints.wristL = [-0.2, 0.65 + pullY, 0.25 - pullZ];
                    joints.wristR = [0.2, 0.65 + pullY, 0.25 - pullZ];
                    joints.elbowL = [-0.35, 0.85 + pullY * 0.8, 0.15 + pullZ * 0.3];
                    joints.elbowR = [0.35, 0.85 + pullY * 0.8, 0.15 + pullZ * 0.3];
                    
                    if (exerciseId.includes("barbell")) {
                        joints.props.push({
                            type: 'barbell',
                            pos: [0, 0.65 + pullY, 0.25 - pullZ],
                            rot: [0.15, 0, 0],
                            length: 1.3
                        });
                    } else {
                        joints.props.push({
                            type: 'dumbbell',
                            pos: joints.wristL,
                            rot: [0.15, 0, 0],
                            size: 0.18
                        });
                    }
                }
            } else if (exerciseId === "reverse_fly") {
                const armSpread = 0.62 * s;
                joints.ankleL = [-0.15, 0.05, 0];
                joints.ankleR = [0.15, 0.05, 0];
                joints.kneeL = [-0.15, 0.4, 0.04];
                joints.kneeR = [0.15, 0.4, 0.04];
                joints.hipL = [-0.15, 0.74, -0.18];
                joints.hipR = [0.15, 0.74, -0.18];
                joints.neck = [0, 1.12, 0.28];
                joints.head = [0, 1.24, 0.39];
                joints.shoulderL = [-0.2, 1.08, 0.27];
                joints.shoulderR = [0.2, 1.08, 0.27];
                joints.elbowL = [-0.24 - armSpread * 0.55, 0.9 + armSpread * 0.25, 0.32];
                joints.elbowR = [0.24 + armSpread * 0.55, 0.9 + armSpread * 0.25, 0.32];
                joints.wristL = [-0.28 - armSpread, 0.76 + armSpread * 0.42, 0.34];
                joints.wristR = [0.28 + armSpread, 0.76 + armSpread * 0.42, 0.34];
                joints.props.push({ type: 'dumbbell', pos: joints.wristL, rot: [0, 0, 0], size: 0.15 });
                joints.props.push({ type: 'dumbbell', pos: joints.wristR, rot: [0, 0, 0], size: 0.15 });
            } else if (exerciseId === "face_pull") {
                // Standing face pull
                joints.ankleL = [-0.15, 0.05, 0];
                joints.ankleR = [0.15, 0.05, -0.15]; // step back stance
                joints.hipL = [-0.15, 0.82, -0.18];
                joints.hipR = [0.15, 0.82, -0.22];
                
                // Pull rope to ears
                const pullZ = -0.38 * s;
                const pullY = 0.12 * s;
                joints.wristL = [-0.25 - 0.1 * s, 1.42 + pullY, 0.45 + pullZ];
                joints.wristR = [0.25 + 0.1 * s, 1.42 + pullY, 0.45 + pullZ];
                joints.elbowL = [-0.38 - 0.08 * s, 1.48 + pullY * 0.5, 0.28 + pullZ * 0.5];
                joints.elbowR = [0.38 + 0.08 * s, 1.48 + pullY * 0.5, 0.28 + pullZ * 0.5];
                
                // Rope line
                joints.props.push({
                    type: 'line',
                    start: [0, 1.55, 0.95],
                    end: [0, 1.42 + pullY, 0.45 + pullZ],
                    color: '#9CA3AF'
                });
            } else if (exerciseId.includes("biceps_curl") || exerciseId.includes("hammer_curl")) {
                // Curls - standing, upper arm stationary
                joints.ankleL = [-0.15, 0.05, 0];
                joints.ankleR = [0.15, 0.05, 0];
                
                joints.elbowL = [-0.22, 1.1, 0.05];
                joints.elbowR = [0.22, 1.1, 0.05];
                
                // Wrists curl up
                const curlAng = s * Math.PI / 1.4; // ~130 degrees
                const cosC = Math.cos(curlAng);
                const sinC = Math.sin(curlAng);
                
                joints.wristL = [-0.22, 1.1 - 0.32 * cosC, 0.05 + 0.32 * sinC];
                joints.wristR = [0.22, 1.1 - 0.32 * cosC, 0.05 + 0.32 * sinC];
                
                // Dumbbell rotation: hammer curl has vertical dumbbells, bicep curl has horizontal
                const isHammer = exerciseId.includes("hammer");
                joints.props.push({
                    type: 'dumbbell',
                    pos: joints.wristL,
                    rot: isHammer ? [1.57, 0, 0] : [0, 0, 0],
                    size: 0.16
                });
                joints.props.push({
                    type: 'dumbbell',
                    pos: joints.wristR,
                    rot: isHammer ? [1.57, 0, 0] : [0, 0, 0],
                    size: 0.16
                });
            } else if (exerciseId === "prone_y_raise" || exerciseId === "reverse_snow_angel") {
                // Lying on front, raising/sweeping arms
                joints.head = [0, 0.22, 0.65];
                joints.neck = [0, 0.18, 0.5];
                joints.shoulderL = [-0.2, 0.18, 0.48];
                joints.shoulderR = [0.2, 0.18, 0.48];
                joints.hipL = [-0.15, 0.12, -0.05];
                joints.hipR = [0.15, 0.12, -0.05];
                joints.kneeL = [-0.15, 0.08, -0.4];
                joints.kneeR = [0.15, 0.08, -0.4];
                joints.ankleL = [-0.15, 0.05, -0.7];
                joints.ankleR = [0.15, 0.05, -0.7];
                
                if (exerciseId === "prone_y_raise") {
                    // Raise hands to Y shape
                    const raiseY = 0.15 * s;
                    joints.elbowL = [-0.38, 0.18 + raiseY, 0.72];
                    joints.elbowR = [0.38, 0.18 + raiseY, 0.72];
                    joints.wristL = [-0.48, 0.18 + raiseY * 1.5, 0.88];
                    joints.wristR = [0.48, 0.18 + raiseY * 1.5, 0.88];
                } else {
                    // Sweep hands from hip to head
                    const sweepAng = s * Math.PI / 1.1; // ~160 deg sweep
                    const cosSw = Math.cos(sweepAng);
                    const sinSw = Math.sin(sweepAng);
                    const r = 0.65;
                    const rY = 0.12 * s;
                    
                    joints.elbowL = [joints.shoulderL[0] - r * 0.6 * sinSw, 0.15 + rY, 0.45 - r * 0.6 * cosSw];
                    joints.elbowR = [joints.shoulderR[0] + r * 0.6 * sinSw, 0.15 + rY, 0.45 - r * 0.6 * cosSw];
                    joints.wristL = [joints.shoulderL[0] - r * sinSw, 0.15 + rY * 1.2, 0.45 - r * cosSw];
                    joints.wristR = [joints.shoulderR[0] + r * sinSw, 0.15 + rY * 1.2, 0.45 - r * cosSw];
                }
            }
        }
        else if (CORE_HOLD.has(exerciseId)) {
            // --- CORE HOLDS (Isometric) ---
            // Subtle breathing motion instead of full movement
            const breath = 0.02 * Math.sin(t * 2);
            
            if (exerciseId === "superman_hold") {
                // Lying on front, chest & legs lifted
                joints.hipL = [-0.15, 0.05, 0];
                joints.hipR = [0.15, 0.05, 0];
                
                // Lifted head, shoulders, chest
                joints.neck = [0, 0.28 + breath, 0.45];
                joints.head = [0, 0.38 + breath, 0.58];
                joints.shoulderL = [-0.2, 0.26 + breath, 0.45];
                joints.shoulderR = [0.2, 0.26 + breath, 0.45];
                
                // Hands extended forward
                joints.elbowL = [-0.25, 0.32 + breath, 0.72];
                joints.elbowR = [0.25, 0.32 + breath, 0.72];
                joints.wristL = [-0.25, 0.38 + breath, 0.95];
                joints.wristR = [0.25, 0.38 + breath, 0.95];
                
                // Legs lifted
                joints.kneeL = [-0.15, 0.18 + breath * 0.5, -0.38];
                joints.kneeR = [0.15, 0.18 + breath * 0.5, -0.38];
                joints.ankleL = [-0.15, 0.28 + breath * 0.8, -0.72];
                joints.ankleR = [0.15, 0.28 + breath * 0.8, -0.72];
            } else if (exerciseId === "side_plank") {
                // Facing side, pivot on L elbow and ankles
                joints.ankleL = [0, 0.05, -0.7];
                joints.ankleR = [0, 0.09, -0.7];
                joints.kneeL = [0, 0.2, -0.4];
                joints.kneeR = [0, 0.24, -0.4];
                
                // Hips elevated
                joints.hipL = [-0.05, 0.38 + breath, -0.05];
                joints.hipR = [0.05, 0.44 + breath, -0.05];
                
                // Left shoulder supported, right shoulder up
                joints.shoulderL = [-0.18, 0.52 + breath, 0.35];
                joints.shoulderR = [0.18, 0.82 + breath, 0.35];
                joints.neck = [0, 0.67 + breath, 0.35];
                joints.head = [0.05, 0.78 + breath, 0.45];
                
                // Elbow support
                joints.elbowL = [-0.18, 0.18, 0.35];
                joints.wristL = [-0.05, 0.18, 0.45];
                
                // R arm on hip
                joints.elbowR = [0.28, 0.65 + breath, 0.25];
                joints.wristR = [0.18, 0.52 + breath, 0.1];
            } else {
                // Standard plank
                // Elbow support
                joints.wristL = [-0.15, 0.18, 0.65];
                joints.wristR = [0.15, 0.18, 0.65];
                joints.elbowL = [-0.18, 0.18, 0.5];
                joints.elbowR = [0.18, 0.18, 0.5];
                
                // Core straight line
                joints.ankleL = [-0.15, 0.05, -0.7];
                joints.ankleR = [0.15, 0.05, -0.7];
                joints.kneeL = [-0.15, 0.16 + breath, -0.4];
                joints.kneeR = [0.15, 0.16 + breath, -0.4];
                
                const hipY = 0.26 + breath;
                joints.hipL = [-0.15, hipY, -0.08];
                joints.hipR = [0.15, hipY, -0.08];
                
                const shY = 0.38 + breath;
                joints.shoulderL = [-0.2, shY, 0.48];
                joints.shoulderR = [0.2, shY, 0.48];
                joints.neck = [0, shY, 0.48];
                joints.head = [0, shY + 0.04, 0.62];
            }
        }
        else if (CORE_OPPOSITE.has(exerciseId)) {
            // --- OPPOSITE LIMBS / ANTIROTATION ---
            const s = phase;
            
            if (exerciseId === "pallof_press") {
                // Standing, press hands forward chống cable kéo sang bên
                joints.ankleL = [-0.22, 0.05, 0];
                joints.ankleR = [0.22, 0.05, 0];
                
                // Press straight out
                const extZ = 0.1 + 0.38 * s;
                joints.wristL = [-0.04, 1.15, extZ];
                joints.wristR = [0.04, 1.15, extZ];
                joints.elbowL = [-0.15 * (1 - s), 1.12, extZ - 0.15 * (1 - s)];
                joints.elbowR = [0.15 * (1 - s), 1.12, extZ - 0.15 * (1 - s)];
                
                // Cable line pulling from side (x=1.2m)
                joints.props.push({
                    type: 'line',
                    start: [1.2, 1.15, 0.1],
                    end: [0, 1.15, extZ],
                    color: '#9CA3AF'
                });
            } else if (exerciseId === "bird_dog") {
                // On all fours (tabletop)
                // Left knee, right wrist remain support
                // Tu the quy: dui tu hong xuong goi (0.37), cang chan dat tren
                // san huong ve sau (0.386). Truoc day dui dai 0.50 con cang chan
                // chi 0.25 - sai ty le giai phau.
                joints.kneeL = [-0.15, 0.18, -0.2];
                joints.ankleL = [-0.15, 0.05, -0.56];
                joints.wristR = [0.15, 0.05, 0.35];
                joints.elbowR = [0.2, 0.22, 0.28];

                // Hip / Shoulder locations
                joints.hipL = [-0.15, 0.55, -0.2];
                joints.hipR = [0.15, 0.55, -0.2];
                joints.shoulderL = [-0.18, 0.58, 0.35];
                joints.shoulderR = [0.18, 0.58, 0.35];
                joints.neck = [0, 0.58, 0.35];
                joints.head = [0, 0.62, 0.48];
                
                // Left arm / Right leg extend out
                // At s=0 (start), they tuck in (R knee forward, L hand in)
                // At s=1 (max), they extend parallel to ground (y=0.55/0.58)
                // Khuyu trai noi tiep tu vai theo do dai co dinh thay vi dat
                // toa do roi rac (truoc day co gian 0.34 -> 0.43).
                const bdUpperArm = 0.28;
                const bdUpDirY = (0.56 * s + 0.15 * (1 - s)) - 0.58;
                const bdUpDirZ = 0.22 * s + 0.02;
                const bdUpNorm = Math.hypot(bdUpDirY, bdUpDirZ) || 1;
                joints.elbowL = [
                    -0.2,
                    0.58 + bdUpperArm * (bdUpDirY / bdUpNorm),
                    0.35 + bdUpperArm * (bdUpDirZ / bdUpNorm)
                ];
                // Canh tay duoi giu do dai that. Truoc day co tay dat tai
                // z = 0.35 + 0.55*s - 0.15*(1-s): o s~0.3 no gan trung khuyu
                // (0.040m) nen cang tay bien mat giua chu ky.
                const bdForeArm = 0.26;
                const bdDirY = -0.35 * (1 - s) + 0.02 * s;
                const bdDirZ = 0.55 + 0.45 * s;
                const bdNorm = Math.hypot(bdDirY, bdDirZ) || 1;
                joints.wristL = [
                    -0.2,
                    joints.elbowL[1] + bdForeArm * (bdDirY / bdNorm),
                    joints.elbowL[2] + bdForeArm * (bdDirZ / bdNorm)
                ];
                
                joints.kneeR = [0.15, 0.55 * s + 0.18 * (1 - s), -0.2 - 0.2 * s];
                // Cang chan phai giu do dai that: truoc day goi va co chan gan
                // trung nhau (0.122) nen doan nay bien mat khi chan duoi ra sau.
                const bdShin = 0.386;
                const bdShDirY = -0.55 * (1 - s) - 0.02 * s;
                const bdShDirZ = -0.45 * (1 - s) - 1.0 * s;
                const bdShNorm = Math.hypot(bdShDirY, bdShDirZ) || 1;
                joints.ankleR = [
                    0.15,
                    Math.max(0.02, joints.kneeR[1] + bdShin * (bdShDirY / bdShNorm)),
                    joints.kneeR[2] + bdShin * (bdShDirZ / bdShNorm)
                ];
            } else {
                // Dead Bug - Lying on back, alternate limbs extend
                // Head/Shoulders flat
                joints.neck = [0, 0.08, -0.3];
                joints.head = [0, 0.08, -0.45];
                joints.shoulderL = [-0.2, 0.08, -0.3];
                joints.shoulderR = [0.2, 0.08, -0.3];
                joints.hipL = [-0.15, 0.08, 0.2];
                joints.hipR = [0.15, 0.08, 0.2];
                
                // Supporting limbs: R arm up, L leg bent
                joints.elbowR = [0.2, 0.32, -0.3];
                joints.wristR = [0.2, 0.6, -0.3];
                joints.kneeL = [-0.15, 0.38, 0.05];
                joints.ankleL = [-0.15, 0.38, 0.35];
                
                // Extending limbs: L arm reaches back, R leg extends straight
                // At s=0, they are bent/vertical. At s=1, they are flat near floor (y=0.1)
                const armY = 0.6 * (1 - s) + 0.1 * s;
                const armZ = -0.3 - 0.3 * s;
                joints.elbowL = [-0.2, 0.32 * (1 - s) + 0.1 * s, -0.3 - 0.18 * s];
                joints.wristL = [-0.2, armY, armZ];
                
                const legY = 0.38 * (1 - s) + 0.1 * s;
                const legZ = 0.05 * (1 - s) + 0.45 * s;
                joints.kneeR = [0.15, 0.38 * (1 - s) + 0.12 * s, 0.05 * (1 - s) + 0.35 * s];
                // Cang chan phai giu do dai that: truoc day o s=1 goi va co chan
                // deu roi ve z ~0.40/0.45 cung do cao nen cang chan sup ve 0 va
                // bien mat. Dat co chan noi tiep tu goi theo huong duoi thang.
                const shinLen = 0.386;
                const shinDirY = -0.32 * (1 - s) - 0.02 * s;
                const shinDirZ = 0.62 * (1 - s) + 1.0 * s;
                const shinNorm = Math.hypot(shinDirY, shinDirZ) || 1;
                joints.ankleR = [
                    0.15,
                    joints.kneeR[1] + shinLen * (shinDirY / shinNorm),
                    joints.kneeR[2] + shinLen * (shinDirZ / shinNorm)
                ];
            }
        }
        else if (KNEE_TUCK.has(exerciseId)) {
            // --- KNEE TUCK / CRUNCH PATTERN ---
            const s = phase;
            
            if (exerciseId === "hanging_knee_raise") {
                // Hanging from bar
                joints.props.push({
                    type: 'barbell',
                    pos: [0, 1.95, 0],
                    rot: [0, 0, 0],
                    length: 1.1
                });
                joints.wristL = [-0.35, 1.95, 0];
                joints.wristR = [0.35, 1.95, 0];

                // Than nguoi TREO duoi xa: truoc day chi dat co tay len xa
                // (y=1.95) ma giu nguyen bo xuong dung mac dinh (vai y=1.42,
                // khuyu y=1.15), nen canh tay duoi bi keo dai 0.81m.
                // Vai treo cach xa mot doan bang chieu dai canh tay duoi + tren.
                joints.shoulderL = [-0.25, 1.42, 0];
                joints.shoulderR = [0.25, 1.42, 0];
                joints.neck = [0, 1.5, 0];
                joints.head = [0, 1.63, 0];
                joints.elbowL = [-0.31, 1.69, 0];
                joints.elbowR = [0.31, 1.69, 0];

                // Legs hang, tuck knees up
                joints.hipL = [-0.15, 0.85, 0];
                joints.hipR = [0.15, 0.85, 0];
                
                // Knees pull up
                const kneeY = 0.45 + 0.4 * s;
                const kneeZ = 0.28 * s;
                joints.kneeL = [-0.15, kneeY, kneeZ];
                joints.kneeR = [0.15, kneeY, kneeZ];
                joints.ankleL = [-0.15, 0.05 + 0.4 * s, 0.2 * s];
                joints.ankleR = [0.15, 0.05 + 0.4 * s, 0.2 * s];
            } else if (exerciseId === "mountain_climber") {
                // Push up position, pump knees
                joints.wristL = [-0.25, 0.05, 0.65];
                joints.wristR = [0.25, 0.05, 0.65];
                joints.elbowL = [-0.3, 0.22, 0.6];
                joints.elbowR = [0.3, 0.22, 0.6];
                joints.shoulderL = [-0.2, 0.58, 0.6];
                joints.shoulderR = [0.2, 0.58, 0.6];
                joints.neck = [0, 0.58, 0.6];
                joints.head = [0, 0.6, 0.72];
                
                joints.hipL = [-0.15, 0.48, 0.05];
                joints.hipR = [0.15, 0.48, 0.05];
                
                // Back leg R straight
                joints.kneeR = [0.15, 0.26, -0.22];
                joints.ankleR = [0.15, 0.05, -0.55];
                
                // Front leg L tucks in
                joints.kneeL = [-0.15, 0.2 + 0.22 * s, 0.05 + 0.22 * s];
                joints.ankleL = [-0.15, 0.05 + 0.15 * s, -0.2 + 0.25 * s];
            } else if (exerciseId === "bicycle_crunch") {
                // Lying on back crunching side to side
                joints.neck = [0, 0.14 + 0.05 * s, -0.3];
                joints.head = [0, 0.16 + 0.05 * s, -0.45];
                // Shoulders twist
                joints.shoulderL = [-0.2, 0.14 + 0.06 * s, -0.3];
                joints.shoulderR = [0.2, 0.14 - 0.06 * s, -0.3];
                
                joints.hipL = [-0.15, 0.08, 0.2];
                joints.hipR = [0.15, 0.08, 0.2];
                
                // Right elbow twists to Left knee
                joints.elbowR = [0.16 - 0.15 * s, 0.25 - 0.05 * s, -0.25 + 0.08 * s];
                joints.wristR = [0.08 - 0.08 * s, 0.25, -0.35 + 0.15 * s];
                
                joints.elbowL = [-0.22, 0.25, -0.25];
                joints.wristL = [-0.15, 0.22, -0.35];
                
                // Left knee tucks in, right leg extends flat
                joints.kneeL = [-0.15, 0.25 + 0.18 * s, 0.1 + 0.18 * s];
                joints.ankleL = [-0.15, 0.15, 0.35];
                
                joints.kneeR = [0.15, 0.22 * (1 - s) + 0.1 * s, 0.2 * (1 - s) + 0.45 * s];
                joints.ankleR = [0.15, 0.15 * (1 - s) + 0.08 * s, 0.4 * (1 - s) + 0.72 * s];
            }
        }
        else if (CARDIO.has(exerciseId)) {
            const sinT = Math.sin(t);
            const cosT = Math.cos(t);
            const bounce = 0.04 * Math.max(0, Math.sin(t * 2));

            if (exerciseId === "jumping_jack") {
                const spread = 0.22 + 0.34 * phase;
                const armY = 0.88 + 0.92 * phase;
                joints.ankleL = [-spread, 0.05 + bounce, 0];
                joints.ankleR = [spread, 0.05 + bounce, 0];
                joints.kneeL = [-spread * 0.6, 0.45 + bounce, 0];
                joints.kneeR = [spread * 0.6, 0.45 + bounce, 0];
                joints.wristL = [-0.55 + 0.38 * phase, armY + bounce, 0];
                joints.wristR = [0.55 - 0.38 * phase, armY + bounce, 0];
                // Khuyu noi tiep giua vai va co tay theo do dai co dinh. Truoc
                // day dat toa do rieng nen ca hai doan tay co gian 11-14cm khi
                // vung tay len xuong.
                const jjUpper = 0.27;
                const jjShY = 1.42 + bounce;
                for (const side of ['L', 'R']) {
                    const sx = side === 'L' ? -0.2 : 0.2;
                    const w = joints['wrist' + side];
                    const vx = w[0] - sx, vy = w[1] - jjShY;
                    const raw = Math.hypot(vx, vy) || 1e-4;
                    const maxR = (jjUpper + 0.26) * 0.995;
                    let dist = raw;
                    if (dist > maxR) {
                        dist = maxR;
                        joints['wrist' + side] = [sx + (vx / raw) * dist, jjShY + (vy / raw) * dist, 0];
                    }
                    const ux = vx / raw, uy = vy / raw;
                    const a = (dist * dist + jjUpper * jjUpper - 0.26 * 0.26) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, jjUpper * jjUpper - a * a));
                    const sgn = side === 'L' ? -1 : 1;
                    joints['elbow' + side] = [
                        sx + ux * a + uy * h * sgn,
                        jjShY + uy * a - ux * h * sgn,
                        0
                    ];
                }
            } else if (exerciseId === "low_impact_jumping_jack") {
                const sideStep = 0.32 * Math.max(0, sinT);
                joints.ankleL = [-0.15 - sideStep, 0.05, 0];
                joints.kneeL = [-0.15 - sideStep * 0.55, 0.45, 0];
                joints.wristL = [-0.2 - 0.35 * phase, 0.88 + 0.72 * phase, 0];
                joints.elbowL = [-0.25 - 0.22 * phase, 1.15 + 0.35 * phase, 0];
                // Tay phai nang nhe nguoc pha voi tay trai. Truoc day chi dat
                // wristR (len toi y=1.13) ma giu elbowR mac dinh o y=1.15, nen
                // hai khop trung nhau (0.028m) va cang tay phai bien mat.
                const rLift = 0.25 * (1 - phase);
                joints.elbowR = [0.24, 1.15 + rLift * 0.4, 0];
                joints.wristR = [0.22, joints.elbowR[1] - 0.26 + rLift * 0.5, 0];
            } else if (exerciseId === "jump_rope") {
                const jumpHeight = 0.08 * Math.max(0, Math.sin(t * 2));
                for (const jointName of ['ankleL', 'ankleR', 'kneeL', 'kneeR', 'hipL', 'hipR', 'shoulderL', 'shoulderR', 'neck', 'head']) {
                    joints[jointName][1] += jumpHeight;
                }
                joints.elbowL = [-0.28, 1.12 + jumpHeight, 0];
                joints.elbowR = [0.28, 1.12 + jumpHeight, 0];
                joints.wristL = [-0.36, 0.92 + jumpHeight, 0.02];
                joints.wristR = [0.36, 0.92 + jumpHeight, 0.02];
                joints.props.push({ type: 'rope', wristL: joints.wristL, wristR: joints.wristR, jumpHeight, phase: t * 2 });
            } else if (exerciseId === "stationary_bike") {
                const pedalRadius = 0.22;
                joints.hipL = [-0.15, 0.78, -0.2];
                joints.hipR = [0.15, 0.78, -0.2];
                joints.neck = [0, 1.35, 0.08];
                joints.head = [0, 1.48, 0.15];
                joints.shoulderL = [-0.2, 1.28, 0.08];
                joints.shoulderR = [0.2, 1.28, 0.08];
                joints.wristL = [-0.28, 1.0, 0.48];
                joints.wristR = [0.28, 1.0, 0.48];
                joints.elbowL = [-0.25, 1.12, 0.28];
                joints.elbowR = [0.25, 1.12, 0.28];
                joints.ankleL = [-0.15, 0.38 + pedalRadius * sinT, 0.2 + pedalRadius * cosT];
                joints.ankleR = [0.15, 0.38 - pedalRadius * sinT, 0.2 - pedalRadius * cosT];
                // Goi giai bang IK 2 xuong tu hong den co chan dang dap vong
                // tron. Truoc day goi chay theo cong thuc rieng nen cang chan
                // co gian 0.22 -> 0.40 (18cm) moi vong dap.
                const bikeThigh = 0.37, bikeShin = 0.38;
                for (const side of ['L', 'R']) {
                    const hip = joints['hip' + side];
                    const ank = joints['ankle' + side];
                    const vy = ank[1] - hip[1], vz = ank[2] - hip[2];
                    let dist = Math.hypot(vy, vz);
                    const maxR = (bikeThigh + bikeShin) * 0.995;
                    if (dist > maxR) dist = maxR;
                    if (dist < 1e-4) dist = 1e-4;
                    const uy = vy / Math.hypot(vy, vz), uz = vz / Math.hypot(vy, vz);
                    const a = (dist * dist + bikeThigh * bikeThigh - bikeShin * bikeShin) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, bikeThigh * bikeThigh - a * a));
                    // Phap tuyen huong ra truoc (dau goi gap ve phia truoc)
                    joints['knee' + side] = [
                        side === 'L' ? -0.15 : 0.15,
                        hip[1] + uy * a + uz * h,
                        hip[2] + uz * a - uy * h
                    ];
                }
                joints.props.push({ type: 'line', start: [0, 0.38, 0.2], end: [0, 0.78, -0.2], color: '#6B7280', width: 5 });
                joints.props.push({ type: 'line', start: [0, 0.38, 0.2], end: [0, 1.02, 0.5], color: '#6B7280', width: 4 });
            } else if (exerciseId === "elliptical") {
                const stride = 0.38 * cosT;
                joints.ankleL = [-0.17, 0.12 + 0.05 * sinT, stride];
                joints.ankleR = [0.17, 0.12 - 0.05 * sinT, -stride];
                // Goi giai bang IK giong cac bai chay/dap xe (truoc day dui co
                // gian 0.30 -> 0.40 theo buoc truot).
                for (const side of ['L', 'R']) {
                    const hip = joints['hip' + side];
                    const ank = joints['ankle' + side];
                    const vy = ank[1] - hip[1], vz = ank[2] - hip[2];
                    const raw = Math.hypot(vy, vz) || 1e-4;
                    const maxR = 0.75 * 0.995;
                    const uy = vy / raw, uz = vz / raw;
                    let dist = raw;
                    if (dist > maxR) {
                        dist = maxR;
                        joints['ankle' + side] = [ank[0], hip[1] + uy * dist, hip[2] + uz * dist];
                    }
                    const a = (dist * dist + 0.37 * 0.37 - 0.38 * 0.38) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, 0.37 * 0.37 - a * a));
                    joints['knee' + side] = [
                        side === 'L' ? -0.17 : 0.17,
                        hip[1] + uy * a + uz * h,
                        hip[2] + uz * a - uy * h
                    ];
                }
                joints.elbowL = [-0.23, 1.18, -0.25 * cosT];
                joints.elbowR = [0.23, 1.18, 0.25 * cosT];
                joints.wristL = [-0.3, 1.42, -0.42 * cosT];
                joints.wristR = [0.3, 1.42, 0.42 * cosT];
                joints.props.push({ type: 'line', start: [-0.3, 0.12, -0.55], end: [-0.3, 1.65, -0.42 * cosT], color: '#6B7280', width: 4 });
                joints.props.push({ type: 'line', start: [0.3, 0.12, 0.55], end: [0.3, 1.65, 0.42 * cosT], color: '#6B7280', width: 4 });
            } else {
                // Brisk walk, treadmill walk/run and high knees share locomotion
                // mechanics, with exercise-specific stride and lift.
                const isRun = exerciseId === "treadmill_run";
                const isHighKnee = exerciseId === "high_knees";
                const stride = isHighKnee ? 0.08 : (isRun ? 0.35 : 0.24);
                const lift = isHighKnee ? 0.42 : (isRun ? 0.22 : 0.08);
                const torsoTilt = isRun ? 0.12 : (isHighKnee ? 0.02 : 0.04);
                const bodyBounce = isRun || isHighKnee ? bounce : 0.015 * Math.sin(t * 2);
                joints.hipL = [-0.15, 0.82 + bodyBounce, 0];
                joints.hipR = [0.15, 0.82 + bodyBounce, 0];
                const legZL = stride * cosT;
                const legZR = -legZL;
                joints.ankleL = [-0.15, 0.05 + lift * Math.max(0, sinT), legZL];
                joints.ankleR = [0.15, 0.05 + lift * Math.max(0, -sinT), legZR];
                // Goi giai bang IK 2 xuong thay vi cong thuc doc lap: truoc day
                // dui va cang chan co gian toi 16cm khi nang goi cao (high_knees
                // 0.17->0.33) vi goi va co chan chay theo hai pha khac nhau.
                const gaitThigh = 0.37, gaitShin = 0.38;
                for (const side of ['L', 'R']) {
                    const hip = joints['hip' + side];
                    const ank = joints['ankle' + side];
                    const vy = ank[1] - hip[1], vz = ank[2] - hip[2];
                    const raw = Math.hypot(vy, vz) || 1e-4;
                    const maxR = (gaitThigh + gaitShin) * 0.995;
                    const uy = vy / raw, uz = vz / raw;
                    let dist = raw;
                    if (dist > maxR) {
                        // Keo co chan ve trong tam voi thay vi de xuong gian ra
                        dist = maxR;
                        joints['ankle' + side] = [ank[0], hip[1] + uy * dist, hip[2] + uz * dist];
                    }
                    const a = (dist * dist + gaitThigh * gaitThigh - gaitShin * gaitShin) / (2 * dist);
                    const h = Math.sqrt(Math.max(0, gaitThigh * gaitThigh - a * a));
                    // Phap tuyen huong ra truoc: dau goi luon gap ve phia truoc
                    joints['knee' + side] = [
                        side === 'L' ? -0.15 : 0.15,
                        hip[1] + uy * a + uz * h,
                        hip[2] + uz * a - uy * h
                    ];
                }
                joints.neck = [0, 1.48 + bodyBounce, torsoTilt];
                joints.head = [0, 1.63 + bodyBounce, torsoTilt + 0.03];
                joints.shoulderL = [-0.2, 1.4 + bodyBounce, torsoTilt];
                joints.shoulderR = [0.2, 1.4 + bodyBounce, torsoTilt];
                const armSwing = isRun ? 0.25 : 0.15;
                joints.elbowL = [-0.22, 1.1 + bodyBounce, -armSwing * cosT];
                joints.elbowR = [0.22, 1.1 + bodyBounce, armSwing * cosT];
                joints.wristL = [-0.22, 0.95 + bodyBounce, -armSwing * 1.5 * cosT + (isRun ? 0.08 : 0)];
                joints.wristR = [0.22, 0.95 + bodyBounce, armSwing * 1.5 * cosT + (isRun ? 0.08 : 0)];
            }
        } else {
            return null;
        }

        return joints;
    }
};
