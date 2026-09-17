// Loop Foundry 1.0 — original rule-based chop and drum generator.
// Pure engine shared by embedded Max v8.codebox and the validation/render tools.
function rng(seed) {
  let s = (seed >>> 0) || 1;
  return function() { s ^= s << 13; s ^= s >>> 17; s ^= s << 5; return (s >>> 0) / 4294967296; };
}
function clamp(x, a, b) { return Math.max(a, Math.min(b, x)); }
function generate(p) {
  const r = rng(p.chopSeed), d = rng(p.drumSeed);
  const cm = rng(p.chopSeed + p.chopMutation * 7919 + 91);
  const dm = rng(p.drumSeed + p.drumMutation * 8191 + 17);
  const repeat = p.repeat / 100, change = p.change / 100, feel = p.feel / 100;
  const density = p.density / 100;
  const notes = [], anchors = [];
  const motif = [0, Math.floor(r()*4), 1+Math.floor(r()*5), Math.floor(r()*8)];
  const patterns = [[0, .75, 1.5, 2, 2.75, 3.5], [0, .5, 1.25, 2, 3, 3.5], [0, 1, 1.75, 2.5, 3, 3.75]];
  const basePattern = patterns[Math.floor(r()*patterns.length)];
  function add(pitch, t, duration, velocity) {
    // Clip boundaries are deliberate: no accidental wrap-around/first-note loss.
    t = clamp(t, 0, 15.97);
    notes.push({pitch, start_time: +t.toFixed(6), duration: +Math.min(duration, 16-t).toFixed(6),
      velocity: Math.round(clamp(velocity, 1, 127)), mute: 0, probability: 1, velocity_deviation: 0});
  }
  for (let bar=0; bar<4; bar++) {
    let starts = basePattern.slice();
    if (bar%2 && r()<change) starts[starts.length-1] = 3.25;
    let prev=motif[0];
    for (let i=0; i<starts.length; i++) {
      const pos=starts[i], span=(i+1<starts.length?starts[i+1]:4)-pos;
      let chop=motif[i%4];
      if (i>0 && r()<repeat) chop=prev;
      if (bar%2 && i>=starts.length-2 && r()<change) chop=Math.floor(r()*8);
      if (p.chopMutation && i>=starts.length-2 && cm()<.65) chop=Math.floor(cm()*8);
      prev=chop;
      const offset=pos===0?0:feel*([0,.016,-.01,.022][i%4]);
      const t=bar*4+pos+offset;
      let roll=i===starts.length-1 && bar%2===1 && r()<repeat*.8;
      const n=roll?Math.max(1,Math.floor(span/.25)):1;
      for(let j=0;j<n;j++) add(48+chop,t+j*.25,roll?.215:Math.max(.09,span*.89),101-(i%3)*9-j*6);
      anchors.push({t:bar*4+pos, strong:i===0||i===3});
    }
  }
  // Drum placements follow chop starts; stable backbeats anchor the phrase.
  for(let bar=0;bar<4;bar++) {
    const ar=rng(p.drumChopSeed || p.chopSeed); ar(); ar(); ar();
    const drumPattern=patterns[Math.floor(ar()*patterns.length)];
    const local=drumPattern.map(t=>({t:bar*4+t}));
    let kicks=[bar*4];
    for(const a of local) if(a.t>bar*4 && Math.abs(a.t%4-1)>.16 && Math.abs(a.t%4-3)>.16 && d()<density*.65) kicks.push(a.t);
    if(kicks.length===1) kicks.push(bar*4+2.5);
    if(p.drumMutation && bar%2 && dm()<.7) kicks.push(bar*4+3.5);
    kicks=[...new Set(kicks)].sort((a,b)=>a-b);
    kicks.forEach((t,i)=>add(36,t+(i?-.021*feel:0),.18,i?94+d()*16:114));
    for(let beat of [1,3]) add(38,bar*4+beat+feel*(beat===1?.025:.042),.19,beat===1?111:117);
    if(d()<change*.8) add(38,bar*4+2.75+feel*.013,.085,40+d()*15);
    for(let step=0;step<8;step++) {
      const draw=d(), jitter=d();
      if(step%2===0 || draw<.25+density*.75) {
        const open=step===7 && bar%2 && d()<change*.5;
        add(open?46:42,bar*4+step*.5+(step%2?.078*feel:0)+(jitter-.5)*.012*feel,open?.22:.085,
          (step%2?58:79)+d()*12);
      }
    }
    if(bar%2 && d()<change*.7) add(60+Math.floor(d()*2),bar*4+3.75,.18,67);
  }
  notes.sort((a,b)=>a.start_time-b.start_time||a.pitch-b.pitch);
  // A monophonic choke group shares a single chop lane. Trim at actual next start.
  const chops=notes.filter(n=>n.pitch>=48&&n.pitch<=55);
  chops.forEach((n,i)=>{if(i+1<chops.length)n.duration=+Math.min(n.duration,Math.max(.01,chops[i+1].start_time-n.start_time-.003)).toFixed(6);});
  return notes;
}
if(typeof module!=='undefined') module.exports={generate,rng};

inlets=1;
outlets=4;
let p={chopSeed:1729,drumSeed:2718,chopMutation:0,drumMutation:0,drumChopSeed:1729,repeat:58,change:35,feel:42,density:64,lockChops:0,lockDrums:0};
function param(key,value) { if(key in p) p[key]=Number(value); }
function msg_dictionary(data) { outlet_dictionary(0,{notes:generate(p)}); }
function bang() { outlet_dictionary(0,{notes:generate(p)}); }
function fresh() {
 if(!p.lockChops) {p.chopSeed=1+((p.chopSeed*73+191)%9998);p.chopMutation=0;outlet(1,'chopSeed',p.chopSeed);outlet(1,'chopMutation',0);}
 if(!p.lockDrums) {p.drumSeed=1+((p.drumSeed*79+193)%9998);p.drumMutation=0;p.drumChopSeed=p.chopSeed;outlet(1,'drumChopSeed',p.drumChopSeed);outlet(1,'drumSeed',p.drumSeed);outlet(1,'drumMutation',0);}
 outlet(3,'bang');
}
function mutate() {
 if(!p.lockChops) {p.chopMutation=(p.chopMutation+1)%10000;outlet(1,'chopMutation',p.chopMutation);}
 if(!p.lockDrums) {p.drumMutation=(p.drumMutation+1)%10000;outlet(1,'drumMutation',p.drumMutation);}
 outlet(3,'bang');
}
