// Block-style cursor smear - cell-snapped trail with inverted background colors
// Physics derived from smear-cursor.nvim (overdamped spring): https://github.com/sphamba/smear-cursor.nvim
//
// ══════════════════════════════════════════════════════════════════════
// PARAMETERS — adjust these to tune the smear behavior
// ══════════════════════════════════════════════════════════════════════
//
// HEAD_RATE       How fast the leading edge reaches the target cursor position.
//                 Higher = head arrives faster, trail stretches more.
//                 Lower = head moves slowly, trail stays compact.
//                 Range: 30–200. Default derived from smear-cursor stiffness=0.9
//
// TAIL_RATE       How fast the trailing edge catches up to the head.
//                 Higher = tail follows quickly, shorter trail duration.
//                 Lower = tail lingers, longer visible trail.
//                 Range: 3–30. Default derived from smear-cursor trailing_stiffness=0.3
//
// TRAIL_OPACITY   Overall opacity of the trail. 1.0 = fully opaque blocks,
//                 0.5 = semi-transparent, blended with background.
//                 Range: 0.0–1.0
//
// TRAIL_RADIUS    Thickness of the trail perpendicular to movement direction,
//                 as a multiplier of the cursor cell size.
//                 Higher = fatter trail, lower = thinner.
//                 Range: 0.3–1.0
//
// TRAIL_TIMEOUT   Maximum animation duration in seconds. Trail rendering stops
//                 after this time even if the tail hasn't fully caught up.
//                 Range: 0.3–2.0
//
// TAIL_FADE_MIN   Minimum opacity at the tail end of the trail (head is always 1.0).
//                 0.0 = tail fully fades out, 1.0 = uniform brightness.
//                 Range: 0.0–1.0
//
// FILL_STEPS      Number of quantization steps for partial block fills at edges.
//                 8 = fine steps (like ▁▂▃▄▅▆▇█), 4 = coarser, 2 = half-blocks only.
//                 Range: 2–16
//
// CHAOS_DECAY     How fast early-frame randomization fades out.
//                 Higher = chaos disappears faster (more subtle).
//                 Lower = chaos lingers longer (more organic start).
//                 Range: 10–100
//
// CHAOS_DROPOUT   Probability of randomly skipping cells in early frames.
//                 Higher = more scattered appearance on small movements.
//                 0.0 = no dropout. Range: 0.0–0.8
//
// CHAOS_SCATTER   How far cells scatter perpendicular to the trail in early frames,
//                 as a multiplier of cell height.
//                 Higher = wider scatter, 0.0 = no scatter. Range: 0.0–5.0
//
// CHAOS_RADIUS    How much the trail radius jitters per-cell in early frames,
//                 as a multiplier of cell height.
//                 Higher = more irregular boundary. Range: 0.0–3.0
//
// FILL_JITTER     Random variation in partial fill amounts at edge cells.
//                 Higher = rougher edges, 0.0 = clean quantized edges.
//                 Range: 0.0–0.5
//
// TRAIL_COLOR     Linear RGB of the trail blocks. Default is palette 14
//                 (#7dfaf3), the light tint of cursor-color #2cf9ed.
//
// TRAIL_INVERT    0.0 = paint TRAIL_COLOR. 1.0 = reverse-video, inverting
//                 whatever is under each cell (the old behaviour, which
//                 picked up the palette on its own). Values between blend.
// ══════════════════════════════════════════════════════════════════════

const float HEAD_RATE = 200.0;
const float TAIL_RATE = 8.0;
const float TRAIL_OPACITY = 1.0;
const float TRAIL_RADIUS = 0.45;
const float TRAIL_TIMEOUT = 0.6;
const float TAIL_FADE_MIN = 0.3;
const float FILL_STEPS = 8.0;
const float CHAOS_DECAY = 40.0;
const float CHAOS_DROPOUT = 0.0;
const float CHAOS_SCATTER = 0.0;
const float CHAOS_RADIUS = 0.0;
const float FILL_JITTER = 0.0;
const vec3 TRAIL_COLOR = vec3(0.490, 0.980, 0.953);
const float TRAIL_INVERT = 0.0;
// Minimum cursor jump, in cells, before any trail is drawn at all. Below this
// the move is treated as typing and nothing renders — 1-cell hops were leaving
// a stub block beside the cursor. Measured in cell units on each axis, so a
// vertical line jump counts the same as a horizontal one; comparing against
// max(cellSize) made the horizontal threshold ~2.3 cells and the vertical 2.0.
const float MIN_MOVE = 1.5;
// How much clear space to keep around the current cursor, in cells. 0.5 is the
// cursor cell exactly, so the trail meets it flush with no gap. Raising this
// toward 1.0 opens a visible gap behind the cursor.
const float CURSOR_CLEARANCE = 0.5;

// SDF: distance from point p to line segment a→b
float sdSegment(vec2 p, vec2 a, vec2 b) {
    vec2 pa = p - a, ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

// Hash for per-cell randomization (seeded by cursor change time)
float cellHash(vec2 cellIdx, float seed) {
    return fract(sin(dot(cellIdx + seed, vec2(127.1, 311.7))) * 43758.5453);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    #if !defined(WEB)
    fragColor = texture(iChannel0, fragCoord.xy / iResolution.xy);
    #endif

    float t = iTime - iTimeCursorChange;
    if (t > TRAIL_TIMEOUT) return;

    // Cell dimensions from cursor size
    vec2 cellSize = iCurrentCursor.zw;
    if (cellSize.x < 1.0 || cellSize.y < 1.0) return;

    // A freshly created tab or window has no previous cursor: ghostty leaves the
    // uniform zeroed, and zero in this Y-up space is the bottom-left corner of
    // the window, so the first cursor move in a new tab smeared up from the
    // bottom. A real cursor rect always has a nonzero size and sits at least
    // window-padding away from the origin, so either test rejects the unset one.
    if (iPreviousCursor.z < 1.0 || iPreviousCursor.w < 1.0) return;
    if (iPreviousCursor.x <= 0.0 && iPreviousCursor.y <= 0.0) return;

    // Cursor centers: xy = top-left corner, zw = size; Y-up coordinate system
    vec2 curCenter = vec2(iCurrentCursor.x + cellSize.x * 0.5,
                          iCurrentCursor.y - cellSize.y * 0.5);
    vec2 prevCenter = vec2(iPreviousCursor.x + iPreviousCursor.z * 0.5,
                           iPreviousCursor.y - iPreviousCursor.w * 0.5);

    float totalDist = distance(curCenter, prevCenter);
    if (length((curCenter - prevCenter) / cellSize) < MIN_MOVE) return;

    // Overdamped spring: head arrives fast, tail follows slowly
    float headAlpha = 1.0 - exp(-HEAD_RATE * t);
    float tailAlpha = 1.0 - exp(-TAIL_RATE * t);
    vec2 head = mix(prevCenter, curCenter, headAlpha);
    vec2 tail = mix(prevCenter, curCenter, tailAlpha);

    float trailLen = distance(head, tail);
    if (trailLen < 0.5) return;

    // Cell grid: which cell does this pixel belong to? The grid's phase has to
    // come from the cursor rect, not from the window corner — window-padding-x/y
    // shift the terminal grid away from fragCoord's origin, so flooring
    // fragCoord/cellSize alone snapped the blocks to a grid offset by the
    // padding and the trail straddled character cells instead of filling them.
    vec2 gridOrigin = vec2(iCurrentCursor.x, iCurrentCursor.y - cellSize.y);
    vec2 cellIdx = floor((fragCoord - gridOrigin) / cellSize);
    vec2 cellOrigin = gridOrigin + cellIdx * cellSize;
    vec2 cellCenterPx = cellOrigin + cellSize * 0.5;
    vec2 subCell = (fragCoord - cellOrigin) / cellSize; // 0→1 within cell

    // Per-cell random values (seeded by cursor change time so each movement is unique)
    float rng = cellHash(cellIdx, iTimeCursorChange);
    float rng2 = cellHash(cellIdx, iTimeCursorChange + 73.0);
    float rng3 = cellHash(cellIdx, iTimeCursorChange + 197.0);

    // Chaos factor: strong randomization in early frames, fades as trail develops
    float chaos = exp(-t * CHAOS_DECAY);

    // Randomly skip cells in early frames (scattered appearance)
    if (rng2 < chaos * CHAOS_DROPOUT) return;

    // Direction-aware radius: for horizontal movement the perpendicular cross-section
    // is vertical (use cellSize.y), for vertical it's horizontal (use cellSize.x).
    vec2 moveDir = (totalDist > 0.0) ? (curCenter - prevCenter) / totalDist : vec2(1.0, 0.0);
    float perpExtent = abs(moveDir.y) * cellSize.x + abs(moveDir.x) * cellSize.y;
    float baseRadius = perpExtent * TRAIL_RADIUS;
    float radiusJitter = chaos * (rng - 0.5) * cellSize.y * CHAOS_RADIUS;
    float radius = baseRadius + radiusJitter;

    // Scatter cells perpendicular to trail axis in early frames
    vec2 trailVec = head - tail;
    vec2 perpDir = (length(trailVec) > 0.0)
        ? normalize(vec2(-trailVec.y, trailVec.x))
        : vec2(0.0, 1.0);
    vec2 scatteredCenter = cellCenterPx + perpDir * chaos * (rng3 - 0.5) * cellSize.y * CHAOS_SCATTER;

    float d = sdSegment(scatteredCenter, tail, head);

    if (d > radius + perpExtent * 0.5) return; // outside trail entirely

    // Don't draw over current cursor cell
    vec2 toCur = abs(cellCenterPx - curCenter);
    if (toCur.x < cellSize.x * CURSOR_CLEARANCE && toCur.y < cellSize.y * CURSOR_CLEARANCE) return;

    // Never draw past the cursor. sdSegment caps at the head, but the radius
    // and the half-cell slack in the cull above still lit the cell one step
    // beyond it, so the smear poked out in front of the cursor instead of
    // trailing behind. Anything whose center sits downstream of the cursor
    // center along the movement axis is dropped.
    if (dot(cellCenterPx - curCenter, moveDir) > 0.0) return;

    // Compute fill fraction for this cell
    float fillAmount;
    if (d <= radius - perpExtent * 0.25) {
        fillAmount = 1.0; // fully inside trail
    } else {
        // Edge cell: partial fill with random jitter, quantized to 8 steps.
        // perpExtent, not cellSize.y — for vertical movement the cross-section
        // is a cell width, and using the height there made the partial blocks
        // taper over the wrong distance.
        fillAmount = 1.0 - (d - (radius - perpExtent * 0.25)) / (perpExtent * 0.75);
        fillAmount = clamp(fillAmount + (rng - 0.5) * FILL_JITTER, 0.0, 1.0);
        fillAmount = floor(fillAmount * FILL_STEPS + 0.5) / FILL_STEPS;
    }
    if (fillAmount <= 0.0) return;

    // For partial fills, determine edge direction to create block character shape
    if (fillAmount < 1.0) {
        // Direction from trail axis to this cell (radial outward)
        vec2 trailDir = head - tail;
        float trailLenSq = dot(trailDir, trailDir);
        float proj = (trailLenSq > 0.0)
            ? clamp(dot(cellCenterPx - tail, trailDir) / trailLenSq, 0.0, 1.0)
            : 0.0;
        vec2 closest = tail + trailDir * proj;
        vec2 edgeDir = cellCenterPx - closest;

        if (abs(edgeDir.y) > abs(edgeDir.x)) {
            // Vertical edge: top/bottom partial block (like ▄▃▂▁ or ▀🮂🮃)
            if (edgeDir.y > 0.0) {
                // Cell above trail axis → fill from bottom
                if (subCell.y > fillAmount) return;
            } else {
                // Cell below trail axis → fill from top
                if (subCell.y < 1.0 - fillAmount) return;
            }
        } else {
            // Horizontal edge: left/right partial block (like ▌▋▊ or ▐)
            if (edgeDir.x > 0.0) {
                // Cell right of trail axis → fill from left
                if (subCell.x > fillAmount) return;
            } else {
                // Cell left of trail axis → fill from right
                if (subCell.x < 1.0 - fillAmount) return;
            }
        }
    }

    // Longitudinal fade: cells closer to tail fade out
    vec2 trailAxis = head - tail;
    float trailAxisLen = length(trailAxis);
    float longitudinal = 0.0;
    if (trailAxisLen > 0.0) {
        longitudinal = dot(cellCenterPx - tail, trailAxis) / (trailAxisLen * trailAxisLen);
        longitudinal = clamp(longitudinal, 0.0, 1.0);
    }
    float fade = (1.0 - tailAlpha) * mix(TAIL_FADE_MIN, 1.0, longitudinal);

    // Color: a flat tint by default, or reverse-video against the cell's
    // background when TRAIL_INVERT is dialled up.
    vec4 bgColor = texture(iChannel0, cellCenterPx / iResolution.xy);
    vec4 trailColor = vec4(mix(TRAIL_COLOR, 1.0 - bgColor.rgb, TRAIL_INVERT), 1.0);

    fragColor = mix(fragColor, trailColor, fade * TRAIL_OPACITY);
}
