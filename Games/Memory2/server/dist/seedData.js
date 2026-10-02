// High quality, vivid, elder-friendly SVG illustrations for starter cards and avatars
export const AVATAR_ELEANOR = `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" width="160" height="160">
  <circle cx="80" cy="80" r="80" fill="#FDE68A"/>
  <circle cx="80" cy="80" r="72" fill="#FEF3C7"/>
  <!-- Hair -->
  <circle cx="80" cy="72" r="44" fill="#E2E8F0"/>
  <circle cx="50" cy="76" r="22" fill="#CBD5E1"/>
  <circle cx="110" cy="76" r="22" fill="#CBD5E1"/>
  <circle cx="80" cy="50" r="24" fill="#E2E8F0"/>
  <!-- Face -->
  <circle cx="80" cy="84" r="34" fill="#FCD34D"/>
  <!-- Glasses -->
  <circle cx="68" cy="82" r="11" fill="none" stroke="#B45309" stroke-width="3.5"/>
  <circle cx="92" cy="82" r="11" fill="none" stroke="#B45309" stroke-width="3.5"/>
  <path d="M 79 82 L 81 82" stroke="#B45309" stroke-width="3.5"/>
  <!-- Eyes -->
  <circle cx="68" cy="82" r="3.5" fill="#1E293B"/>
  <circle cx="92" cy="82" r="3.5" fill="#1E293B"/>
  <!-- Cheeks -->
  <circle cx="58" cy="94" r="6" fill="#F87171" opacity="0.6"/>
  <circle cx="102" cy="94" r="6" fill="#F87171" opacity="0.6"/>
  <!-- Smile -->
  <path d="M 72 97 Q 80 106 88 97" fill="none" stroke="#B45309" stroke-width="3.5" stroke-linecap="round"/>
  <!-- Collar / Clothes -->
  <path d="M 46 142 Q 80 120 114 142 L 126 160 L 34 160 Z" fill="#3B82F6"/>
  <path d="M 72 132 L 80 144 L 88 132" fill="#DBEAFE"/>
</svg>
`)}`;
export const AVATAR_ARTHUR = `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 160 160" width="160" height="160">
  <circle cx="80" cy="80" r="80" fill="#BAE6FD"/>
  <circle cx="80" cy="80" r="72" fill="#E0F2FE"/>
  <!-- Hair on sides -->
  <circle cx="50" cy="74" r="16" fill="#94A3B8"/>
  <circle cx="110" cy="74" r="16" fill="#94A3B8"/>
  <!-- Face -->
  <circle cx="80" cy="80" r="36" fill="#FDE68A"/>
  <!-- Mustache -->
  <path d="M 68 96 Q 80 94 92 96 Q 80 106 68 96" fill="#94A3B8"/>
  <!-- Eyes -->
  <circle cx="68" cy="78" r="3.5" fill="#0F172A"/>
  <circle cx="92" cy="78" r="3.5" fill="#0F172A"/>
  <!-- Eyebrows -->
  <path d="M 62 70 Q 68 66 74 70" fill="none" stroke="#94A3B8" stroke-width="3" stroke-linecap="round"/>
  <path d="M 86 70 Q 92 66 98 70" fill="none" stroke="#94A3B8" stroke-width="3" stroke-linecap="round"/>
  <!-- Smile -->
  <path d="M 72 102 Q 80 108 88 102" fill="none" stroke="#92400E" stroke-width="2.5" stroke-linecap="round"/>
  <!-- Clothes -->
  <path d="M 44 142 Q 80 122 116 142 L 126 160 L 34 160 Z" fill="#059669"/>
  <path d="M 80 134 L 80 160" stroke="#047857" stroke-width="2.5"/>
</svg>
`)}`;
// Curated vividly illustrated cognitive picture cards
export const SAMPLE_CARD_IMAGES = {
    goldenDog: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#7DD3FC"/>
      <stop offset="100%" stop-color="#BAE6FD"/>
    </linearGradient>
    <linearGradient id="grass" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#4ADE80"/>
      <stop offset="100%" stop-color="#16A34A"/>
    </linearGradient>
  </defs>
  <!-- Background -->
  <rect width="600" height="240" fill="url(#sky)"/>
  <rect y="240" width="600" height="160" fill="url(#grass)"/>
  <circle cx="500" cy="80" r="45" fill="#FACC15" opacity="0.9"/>
  <!-- Clouds -->
  <ellipse cx="120" cy="90" rx="60" ry="25" fill="#FFFFFF" opacity="0.85"/>
  <ellipse cx="155" cy="75" rx="40" ry="28" fill="#FFFFFF" opacity="0.85"/>
  <ellipse cx="320" cy="110" rx="55" ry="22" fill="#FFFFFF" opacity="0.75"/>
  <!-- Red Dog Ball -->
  <circle cx="160" cy="310" r="26" fill="#EF4444"/>
  <circle cx="152" cy="302" r="7" fill="#FCA5A5"/>
  <!-- Golden Retriever Dog -->
  <ellipse cx="360" cy="280" rx="105" ry="55" fill="#F59E0B"/>
  <circle cx="450" cy="230" r="45" fill="#F59E0B"/>
  <!-- Ears -->
  <ellipse cx="440" cy="245" rx="16" ry="34" fill="#D97706" transform="rotate(-15 440 245)"/>
  <ellipse cx="485" cy="240" rx="14" ry="30" fill="#D97706" transform="rotate(15 485 240)"/>
  <!-- Dog Face -->
  <ellipse cx="480" cy="242" rx="20" ry="14" fill="#FDE68A"/>
  <circle cx="492" cy="238" r="8" fill="#1F2937"/>
  <circle cx="462" cy="218" r="5" fill="#1F2937"/>
  <!-- Red Collar -->
  <path d="M 415 255 Q 435 275 450 260" fill="none" stroke="#DC2626" stroke-width="12" stroke-linecap="round"/>
  <circle cx="438" cy="272" r="6" fill="#FBBF24"/>
  <!-- Paws -->
  <ellipse cx="270" cy="320" rx="35" ry="16" fill="#D97706"/>
  <ellipse cx="380" cy="322" rx="35" ry="16" fill="#D97706"/>
  <ellipse cx="450" cy="315" rx="28" ry="14" fill="#D97706"/>
  <!-- Tail -->
  <path d="M 260 270 Q 220 230 235 200" fill="none" stroke="#F59E0B" stroke-width="20" stroke-linecap="round"/>
</svg>
`)}`,
    redTeapot: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <!-- Wooden Table & Wallpaper -->
  <rect width="600" height="260" fill="#FEF3C7"/>
  <!-- Wallpaper subtle stripes -->
  <path d="M 60 0 L 60 260 M 160 0 L 160 260 M 260 0 L 260 260 M 360 0 L 360 260 M 460 0 L 460 260 M 560 0 L 560 260" stroke="#FDE68A" stroke-width="16" opacity="0.4"/>
  <!-- Table Top -->
  <rect y="260" width="600" height="140" fill="#92400E"/>
  <rect y="260" width="600" height="20" fill="#B45309"/>
  <!-- White Lace Placemat -->
  <ellipse cx="300" cy="315" rx="190" ry="45" fill="#FFFFFF" stroke="#E2E8F0" stroke-width="4"/>
  <!-- Big Red Teapot -->
  <!-- Handle -->
  <path d="M 200 240 Q 130 220 170 170 Q 210 140 230 190" fill="none" stroke="#DC2626" stroke-width="22" stroke-linecap="round"/>
  <!-- Spout -->
  <path d="M 360 220 Q 420 210 430 150 Q 415 150 395 180" fill="#DC2626" stroke="#991B1B" stroke-width="3"/>
  <!-- Pot Body -->
  <circle cx="295" cy="225" r="85" fill="#EF4444"/>
  <circle cx="295" cy="225" r="85" fill="none" stroke="#B91C1C" stroke-width="6"/>
  <!-- Lid & Knob -->
  <ellipse cx="295" cy="142" rx="42" ry="12" fill="#B91C1C"/>
  <circle cx="295" cy="124" r="14" fill="#FBBF24"/>
  <!-- Shine -->
  <ellipse cx="265" cy="195" rx="18" ry="32" fill="#F87171" opacity="0.6" transform="rotate(-25 265 195)"/>
  <!-- Blue Teacup Beside It -->
  <ellipse cx="450" cy="305" rx="36" ry="12" fill="#3B82F6"/>
  <path d="M 420 300 Q 450 345 480 300 Z" fill="#2563EB"/>
  <ellipse cx="450" cy="326" rx="46" ry="8" fill="#1D4ED8"/>
</svg>
`)}`,
    sunflowers: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <!-- Sky -->
  <rect width="600" height="400" fill="#60A5FA"/>
  <!-- Ground Hill -->
  <circle cx="300" cy="650" r="380" fill="#15803D"/>
  <!-- Bright Sun -->
  <circle cx="80" cy="70" r="48" fill="#FBBF24"/>
  <!-- Stems and Leaves -->
  <path d="M 210 380 Q 200 240 220 180" stroke="#166534" stroke-width="16" fill="none"/>
  <path d="M 380 380 Q 400 230 370 150" stroke="#166534" stroke-width="18" fill="none"/>
  <path d="M 200 280 Q 130 270 150 240 Q 180 260 200 280" fill="#22C55E"/>
  <path d="M 385 270 Q 455 260 440 230 Q 405 250 385 270" fill="#22C55E"/>
  <!-- Sunflower 1 (Left) -->
  <g transform="translate(220, 180)">
    <!-- Yellow Petals -->
    <circle cx="0" cy="0" r="75" fill="#FACC15" stroke="#EAB308" stroke-dasharray="25 6" stroke-width="26"/>
    <!-- Seed Center -->
    <circle cx="0" cy="0" r="46" fill="#78350F"/>
    <circle cx="0" cy="0" r="38" fill="#92400E"/>
  </g>
  <!-- Sunflower 2 (Right - Taller) -->
  <g transform="translate(370, 140)">
    <circle cx="0" cy="0" r="90" fill="#FACC15" stroke="#EAB308" stroke-dasharray="28 8" stroke-width="32"/>
    <circle cx="0" cy="0" r="54" fill="#78350F"/>
    <circle cx="0" cy="0" r="44" fill="#92400E"/>
  </g>
  <!-- Small Red Ladybug -->
  <ellipse cx="230" cy="180" rx="9" ry="7" fill="#DC2626"/>
  <circle cx="230" cy="180" r="2" fill="#000000"/>
</svg>
`)}`,
    vintageCar: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <!-- Sunset background -->
  <rect width="600" height="250" fill="#FDE68A"/>
  <rect y="250" width="600" height="150" fill="#475569"/>
  <!-- Road Yellow Line -->
  <rect y="315" x="50" width="100" height="12" fill="#FBBF24"/>
  <rect y="315" x="250" width="100" height="12" fill="#FBBF24"/>
  <rect y="315" x="450" width="100" height="12" fill="#FBBF24"/>
  <!-- Palm tree silhouettes -->
  <path d="M 90 250 Q 80 120 70 80" stroke="#78350F" stroke-width="12" fill="none"/>
  <!-- Vintage Turquoise Convertible Car -->
  <!-- Car Body Main -->
  <path d="M 120 250 Q 140 190 220 180 L 370 180 Q 420 190 480 230 L 510 250 L 100 250 Z" fill="#06B6D4"/>
  <path d="M 100 250 L 510 250 L 500 280 L 110 280 Z" fill="#0891B2"/>
  <!-- Chrome Bumper -->
  <rect x="90" y="260" width="25" height="16" rx="4" fill="#E2E8F0" stroke="#94A3B8" stroke-width="2"/>
  <rect x="495" y="260" width="25" height="16" rx="4" fill="#E2E8F0" stroke="#94A3B8" stroke-width="2"/>
  <!-- Windshield -->
  <path d="M 240 180 L 280 125 L 350 125 L 340 180 Z" fill="#E0F2FE" stroke="#0891B2" stroke-width="4" opacity="0.85"/>
  <!-- Steering Wheel -->
  <circle cx="310" cy="155" r="14" fill="none" stroke="#1E293B" stroke-width="4"/>
  <!-- Headlight glowing -->
  <circle cx="500" cy="242" r="14" fill="#FEF08A" stroke="#CBD5E1" stroke-width="3"/>
  <!-- Wheels -->
  <circle cx="180" cy="280" r="36" fill="#1E293B"/>
  <circle cx="180" cy="280" r="20" fill="#E2E8F0" stroke="#94A3B8" stroke-width="4"/>
  <circle cx="430" cy="280" r="36" fill="#1E293B"/>
  <circle cx="430" cy="280" r="20" fill="#E2E8F0" stroke="#94A3B8" stroke-width="4"/>
</svg>
`)}`,
    fruitBowl: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <!-- Kitchen Wall & Counter -->
  <rect width="600" height="240" fill="#F8FAFC"/>
  <!-- Checkered Kitchen backsplash -->
  <path d="M 0 180 L 600 180 M 0 120 L 600 120" stroke="#E2E8F0" stroke-width="3"/>
  <!-- Granite Counter -->
  <rect y="240" width="600" height="160" fill="#334155"/>
  <!-- White Ceramic Bowl -->
  <ellipse cx="300" cy="305" rx="170" ry="40" fill="#E2E8F0"/>
  <path d="M 140 250 Q 300 370 460 250 Q 300 230 140 250 Z" fill="#FFFFFF" stroke="#CBD5E1" stroke-width="4"/>
  <!-- Two Yellow Bananas -->
  <path d="M 230 190 Q 300 250 390 200 Q 300 220 230 190" fill="#FACC15" stroke="#CA8A04" stroke-width="3"/>
  <path d="M 220 205 Q 290 265 380 215 Q 290 235 220 205" fill="#EAB308" stroke="#A16207" stroke-width="3"/>
  <!-- Red Apples -->
  <circle cx="250" cy="235" r="36" fill="#DC2626"/>
  <circle cx="240" cy="225" r="8" fill="#F87171" opacity="0.6"/>
  <circle cx="340" cy="235" r="34" fill="#EF4444"/>
  <!-- Green Pear -->
  <ellipse cx="300" cy="220" rx="26" ry="36" fill="#84CC16"/>
  <circle cx="300" cy="195" r="18" fill="#84CC16"/>
  <rect x="298" y="172" width="4" height="12" fill="#78350F"/>
</svg>
`)}`,
    redCardinal: `data:image/svg+xml;utf8,${encodeURIComponent(`
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 600 400" width="600" height="400">
  <!-- Snowy Winter Blue Sky -->
  <rect width="600" height="400" fill="#BAE6FD"/>
  <!-- Distant snowy pines -->
  <polygon points="80,260 120,180 160,260" fill="#0284C7" opacity="0.4"/>
  <polygon points="120,260 160,150 200,260" fill="#0284C7" opacity="0.5"/>
  <!-- Snow Bank -->
  <rect y="310" width="600" height="90" fill="#F0F9FF"/>
  <!-- Wooden Birdhouse Post -->
  <rect x="285" y="190" width="30" height="150" fill="#78350F"/>
  <!-- Birdhouse Body -->
  <rect x="240" y="150" width="120" height="90" fill="#A16207"/>
  <!-- Round Hole Entrance -->
  <circle cx="300" cy="195" r="22" fill="#1C1917"/>
  <!-- Wooden Perch -->
  <rect x="295" y="222" width="10" height="20" fill="#78350F"/>
  <!-- Roof with Snow -->
  <polygon points="215,150 300,80 385,150" fill="#B45309"/>
  <polygon points="210,148 300,75 390,148 375,155 300,90 225,155" fill="#FFFFFF"/>
  <!-- Red Cardinal Bird Standing on Roof -->
  <!-- Body -->
  <ellipse cx="350" cy="85" rx="30" ry="18" fill="#DC2626" transform="rotate(-15 350 85)"/>
  <!-- Crest and Head -->
  <circle cx="370" cy="72" r="16" fill="#DC2626"/>
  <polygon points="365,65 375,48 380,68" fill="#B91C1C"/>
  <!-- Black Mask -->
  <polygon points="370,70 385,73 376,82" fill="#0C0A09"/>
  <!-- Yellow Beak -->
  <polygon points="383,71 398,75 383,79" fill="#F59E0B"/>
  <!-- Eye -->
  <circle cx="373" cy="71" r="2.5" fill="#FFFFFF"/>
  <!-- Tail feathers -->
  <polygon points="325,95 295,120 315,100" fill="#B91C1C"/>
</svg>
`)}`
};
