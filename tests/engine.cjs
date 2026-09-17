// Run from the repository root with: npm test
const fs=require('fs'),vm=require('vm'),assert=require('assert');
const {generate}=require('../engine.js');
const base={chopSeed:1729,drumSeed:2718,drumChopSeed:1729,chopMutation:0,drumMutation:0,repeat:58,change:35,feel:42,density:64};
let cases=0;
for(let seed=1;seed<=100;seed++)for(let feel of [0,42,100]) {
 const p={...base,chopSeed:seed,drumSeed:seed*7,drumChopSeed:seed,feel}; const n=generate(p);
 assert.deepStrictEqual(n,generate(p));
 n.forEach(x=>{assert(Number.isFinite(x.start_time));assert(x.start_time>=0&&x.start_time<16);assert(x.duration>0&&x.start_time+x.duration<=16.000001);assert(x.velocity>=1&&x.velocity<=127);});
 const keys=n.map(x=>x.pitch+':'+x.start_time);assert.equal(new Set(keys).size,keys.length);
 assert.equal(n.filter(x=>x.pitch===38&&x.velocity>90).length,8);
 const c=n.filter(x=>x.pitch>=48&&x.pitch<=55);for(let i=1;i<c.length;i++) assert(c[i-1].start_time+c[i-1].duration<c[i].start_time);
 cases++;
}
let context={outlet:()=>{},outlet_dictionary:()=>{}};vm.createContext(context);vm.runInContext(fs.readFileSync('engine.js','utf8'),context);
function run(s){return vm.runInContext(s,context)}
run('param("lockDrums",1)');const before=run('JSON.stringify(generate(p).filter(n=>n.pitch<48||n.pitch>=60))');run('fresh()');assert.equal(before,run('JSON.stringify(generate(p).filter(n=>n.pitch<48||n.pitch>=60))'));
run('param("lockDrums",0);param("lockChops",1)');const cBefore=run('JSON.stringify(generate(p).filter(n=>n.pitch>=48&&n.pitch<=55))');run('fresh();mutate()');assert.equal(cBefore,run('JSON.stringify(generate(p).filter(n=>n.pitch>=48&&n.pitch<=55))'));
console.log(`PASS: ${cases} deterministic patterns; bounds, collisions, backbeats, choke durations and both locks.`);
