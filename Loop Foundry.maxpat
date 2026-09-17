{
  "patcher": {
    "fileversion": 1,
    "appversion": {
      "major": 9,
      "minor": 0,
      "revision": 0,
      "architecture": "x64",
      "modernui": 1
    },
    "classnamespace": "box",
    "rect": [
      0,
      0,
      1000,
      800
    ],
    "openrect": [
      0,
      0,
      152,
      147
    ],
    "bglocked": 0,
    "openinpresentation": 0,
    "default_fontsize": 10,
    "default_fontface": 0,
    "default_fontname": "Arial Bold",
    "gridonopen": 1,
    "gridsize": [
      8,
      8
    ],
    "gridsnaponopen": 1,
    "objectsnaponopen": 1,
    "statusbarvisible": 2,
    "toolbarvisible": 1,
    "lefttoolbarpinned": 0,
    "toptoolbarpinned": 0,
    "righttoolbarpinned": 0,
    "bottomtoolbarpinned": 0,
    "toolbars_unpinned_last_save": 0,
    "tallnewobj": 0,
    "boxanimatetime": 500,
    "enablehscroll": 1,
    "enablevscroll": 1,
    "devicewidth": 152,
    "description": "Four-bar chop and drum generator. Use an empty four-bar MIDI clip with Loop Foundry Kit.",
    "digest": "",
    "tags": "",
    "style": "",
    "subpatcher_template": "",
    "assistshowspatchername": 0,
    "boxes": [
      {
        "box": {
          "id": "title",
          "maxclass": "comment",
          "patching_rect": [
            5,
            0,
            145,
            14
          ],
          "text": "LOOP FOUNDRY",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            5,
            0,
            145,
            14
          ]
        }
      },
      {
        "box": {
          "id": "in",
          "maxclass": "newobj",
          "patching_rect": [
            200,
            30,
            100,
            22
          ],
          "text": "live.miditool.in",
          "numinlets": 1,
          "numoutlets": 3
        }
      },
      {
        "box": {
          "id": "engine",
          "maxclass": "v8.codebox",
          "patching_rect": [
            200,
            120,
            650,
            420
          ],
          "code": "// Loop Foundry 1.0 — original rule-based chop and drum generator.\n// Pure engine shared by embedded Max v8.codebox and the validation/render tools.\nfunction rng(seed) {\n  let s = (seed >>> 0) || 1;\n  return function() { s ^= s << 13; s ^= s >>> 17; s ^= s << 5; return (s >>> 0) / 4294967296; };\n}\nfunction clamp(x, a, b) { return Math.max(a, Math.min(b, x)); }\nfunction generate(p) {\n  const r = rng(p.chopSeed), d = rng(p.drumSeed);\n  const cm = rng(p.chopSeed + p.chopMutation * 7919 + 91);\n  const dm = rng(p.drumSeed + p.drumMutation * 8191 + 17);\n  const repeat = p.repeat / 100, change = p.change / 100, feel = p.feel / 100;\n  const density = p.density / 100;\n  const notes = [], anchors = [];\n  const motif = [0, Math.floor(r()*4), 1+Math.floor(r()*5), Math.floor(r()*8)];\n  const patterns = [[0, .75, 1.5, 2, 2.75, 3.5], [0, .5, 1.25, 2, 3, 3.5], [0, 1, 1.75, 2.5, 3, 3.75]];\n  const basePattern = patterns[Math.floor(r()*patterns.length)];\n  function add(pitch, t, duration, velocity) {\n    // Clip boundaries are deliberate: no accidental wrap-around/first-note loss.\n    t = clamp(t, 0, 15.97);\n    notes.push({pitch, start_time: +t.toFixed(6), duration: +Math.min(duration, 16-t).toFixed(6),\n      velocity: Math.round(clamp(velocity, 1, 127)), mute: 0, probability: 1, velocity_deviation: 0});\n  }\n  for (let bar=0; bar<4; bar++) {\n    let starts = basePattern.slice();\n    if (bar%2 && r()<change) starts[starts.length-1] = 3.25;\n    let prev=motif[0];\n    for (let i=0; i<starts.length; i++) {\n      const pos=starts[i], span=(i+1<starts.length?starts[i+1]:4)-pos;\n      let chop=motif[i%4];\n      if (i>0 && r()<repeat) chop=prev;\n      if (bar%2 && i>=starts.length-2 && r()<change) chop=Math.floor(r()*8);\n      if (p.chopMutation && i>=starts.length-2 && cm()<.65) chop=Math.floor(cm()*8);\n      prev=chop;\n      const offset=pos===0?0:feel*([0,.016,-.01,.022][i%4]);\n      const t=bar*4+pos+offset;\n      let roll=i===starts.length-1 && bar%2===1 && r()<repeat*.8;\n      const n=roll?Math.max(1,Math.floor(span/.25)):1;\n      for(let j=0;j<n;j++) add(48+chop,t+j*.25,roll?.215:Math.max(.09,span*.89),101-(i%3)*9-j*6);\n      anchors.push({t:bar*4+pos, strong:i===0||i===3});\n    }\n  }\n  // Drum placements follow chop starts; stable backbeats anchor the phrase.\n  for(let bar=0;bar<4;bar++) {\n    const ar=rng(p.drumChopSeed || p.chopSeed); ar(); ar(); ar();\n    const drumPattern=patterns[Math.floor(ar()*patterns.length)];\n    const local=drumPattern.map(t=>({t:bar*4+t}));\n    let kicks=[bar*4];\n    for(const a of local) if(a.t>bar*4 && Math.abs(a.t%4-1)>.16 && Math.abs(a.t%4-3)>.16 && d()<density*.65) kicks.push(a.t);\n    if(kicks.length===1) kicks.push(bar*4+2.5);\n    if(p.drumMutation && bar%2 && dm()<.7) kicks.push(bar*4+3.5);\n    kicks=[...new Set(kicks)].sort((a,b)=>a-b);\n    kicks.forEach((t,i)=>add(36,t+(i?-.021*feel:0),.18,i?94+d()*16:114));\n    for(let beat of [1,3]) add(38,bar*4+beat+feel*(beat===1?.025:.042),.19,beat===1?111:117);\n    if(d()<change*.8) add(38,bar*4+2.75+feel*.013,.085,40+d()*15);\n    for(let step=0;step<8;step++) {\n      const draw=d(), jitter=d();\n      if(step%2===0 || draw<.25+density*.75) {\n        const open=step===7 && bar%2 && d()<change*.5;\n        add(open?46:42,bar*4+step*.5+(step%2?.078*feel:0)+(jitter-.5)*.012*feel,open?.22:.085,\n          (step%2?58:79)+d()*12);\n      }\n    }\n    if(bar%2 && d()<change*.7) add(60+Math.floor(d()*2),bar*4+3.75,.18,67);\n  }\n  notes.sort((a,b)=>a.start_time-b.start_time||a.pitch-b.pitch);\n  // A monophonic choke group shares a single chop lane. Trim at actual next start.\n  const chops=notes.filter(n=>n.pitch>=48&&n.pitch<=55);\n  chops.forEach((n,i)=>{if(i+1<chops.length)n.duration=+Math.min(n.duration,Math.max(.01,chops[i+1].start_time-n.start_time-.003)).toFixed(6);});\n  return notes;\n}\nif(typeof module!=='undefined') module.exports={generate,rng};\n\ninlets=1;\noutlets=4;\nlet p={chopSeed:1729,drumSeed:2718,chopMutation:0,drumMutation:0,drumChopSeed:1729,repeat:58,change:35,feel:42,density:64,lockChops:0,lockDrums:0};\nfunction param(key,value) { if(key in p) p[key]=Number(value); }\nfunction msg_dictionary(data) { outlet_dictionary(0,{notes:generate(p)}); }\nfunction bang() { outlet_dictionary(0,{notes:generate(p)}); }\nfunction fresh() {\n if(!p.lockChops) {p.chopSeed=1+((p.chopSeed*73+191)%9998);p.chopMutation=0;outlet(1,'chopSeed',p.chopSeed);outlet(1,'chopMutation',0);}\n if(!p.lockDrums) {p.drumSeed=1+((p.drumSeed*79+193)%9998);p.drumMutation=0;p.drumChopSeed=p.chopSeed;outlet(1,'drumChopSeed',p.drumChopSeed);outlet(1,'drumSeed',p.drumSeed);outlet(1,'drumMutation',0);}\n outlet(3,'bang');\n}\nfunction mutate() {\n if(!p.lockChops) {p.chopMutation=(p.chopMutation+1)%10000;outlet(1,'chopMutation',p.chopMutation);}\n if(!p.lockDrums) {p.drumMutation=(p.drumMutation+1)%10000;outlet(1,'drumMutation',p.drumMutation);}\n outlet(3,'bang');\n}\n",
          "filename": "none",
          "numinlets": 1,
          "numoutlets": 4,
          "outlettype": [
            "",
            "",
            "",
            ""
          ],
          "saved_object_attributes": {
            "parameter_enable": 0
          }
        }
      },
      {
        "box": {
          "id": "out",
          "maxclass": "newobj",
          "patching_rect": [
            200,
            590,
            105,
            22
          ],
          "text": "live.miditool.out",
          "numinlets": 1,
          "numoutlets": 0
        }
      },
      {
        "box": {
          "id": "labelchopSeed",
          "maxclass": "comment",
          "patching_rect": [
            5,
            15,
            70,
            14
          ],
          "text": "Chop seed",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            5,
            15,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "chopSeed",
          "maxclass": "live.numbox",
          "patching_rect": [
            5,
            28,
            67,
            16
          ],
          "minimum": 1,
          "maximum": 9999,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "chopSeed",
          "presentation": 1,
          "presentation_rect": [
            5,
            28,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Chop seed",
              "parameter_shortname": "Chop seed",
              "parameter_type": 0,
              "parameter_mmin": 1,
              "parameter_mmax": 9999,
              "parameter_initial": [
                1729
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "prechopSeed",
          "maxclass": "newobj",
          "patching_rect": [
            200,
            710,
            170,
            22
          ],
          "text": "prepend param chopSeed"
        }
      },
      {
        "box": {
          "id": "labeldrumSeed",
          "maxclass": "comment",
          "patching_rect": [
            79,
            15,
            70,
            14
          ],
          "text": "Drum seed",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            79,
            15,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "drumSeed",
          "maxclass": "live.numbox",
          "patching_rect": [
            79,
            28,
            67,
            16
          ],
          "minimum": 1,
          "maximum": 9999,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "drumSeed",
          "presentation": 1,
          "presentation_rect": [
            79,
            28,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Drum seed",
              "parameter_shortname": "Drum seed",
              "parameter_type": 0,
              "parameter_mmin": 1,
              "parameter_mmax": 9999,
              "parameter_initial": [
                2718
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "predrumSeed",
          "maxclass": "newobj",
          "patching_rect": [
            380,
            710,
            170,
            22
          ],
          "text": "prepend param drumSeed"
        }
      },
      {
        "box": {
          "id": "labelrepeat",
          "maxclass": "comment",
          "patching_rect": [
            5,
            47,
            70,
            14
          ],
          "text": "Repeat",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            5,
            47,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "repeat",
          "maxclass": "live.numbox",
          "patching_rect": [
            5,
            60,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 100,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "repeat",
          "presentation": 1,
          "presentation_rect": [
            5,
            60,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Repeat",
              "parameter_shortname": "Repeat",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 100,
              "parameter_initial": [
                58
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "prerepeat",
          "maxclass": "newobj",
          "patching_rect": [
            560,
            710,
            170,
            22
          ],
          "text": "prepend param repeat"
        }
      },
      {
        "box": {
          "id": "labelchange",
          "maxclass": "comment",
          "patching_rect": [
            79,
            47,
            70,
            14
          ],
          "text": "Change",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            79,
            47,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "change",
          "maxclass": "live.numbox",
          "patching_rect": [
            79,
            60,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 100,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "change",
          "presentation": 1,
          "presentation_rect": [
            79,
            60,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Change",
              "parameter_shortname": "Change",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 100,
              "parameter_initial": [
                35
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "prechange",
          "maxclass": "newobj",
          "patching_rect": [
            740,
            710,
            170,
            22
          ],
          "text": "prepend param change"
        }
      },
      {
        "box": {
          "id": "labelfeel",
          "maxclass": "comment",
          "patching_rect": [
            5,
            79,
            70,
            14
          ],
          "text": "Feel",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            5,
            79,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "feel",
          "maxclass": "live.numbox",
          "patching_rect": [
            5,
            92,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 100,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "feel",
          "presentation": 1,
          "presentation_rect": [
            5,
            92,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Feel",
              "parameter_shortname": "Feel",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 100,
              "parameter_initial": [
                42
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "prefeel",
          "maxclass": "newobj",
          "patching_rect": [
            200,
            740,
            170,
            22
          ],
          "text": "prepend param feel"
        }
      },
      {
        "box": {
          "id": "labeldensity",
          "maxclass": "comment",
          "patching_rect": [
            79,
            79,
            70,
            14
          ],
          "text": "Density",
          "fontsize": 9,
          "fontname": "Arial",
          "textcolor": [
            0.85,
            0.85,
            0.85,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            79,
            79,
            70,
            14
          ]
        }
      },
      {
        "box": {
          "id": "density",
          "maxclass": "live.numbox",
          "patching_rect": [
            79,
            92,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 100,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "density",
          "presentation": 1,
          "presentation_rect": [
            79,
            92,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Density",
              "parameter_shortname": "Density",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 100,
              "parameter_initial": [
                64
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "predensity",
          "maxclass": "newobj",
          "patching_rect": [
            380,
            740,
            170,
            22
          ],
          "text": "prepend param density"
        }
      },
      {
        "box": {
          "id": "chopMutation",
          "maxclass": "live.numbox",
          "patching_rect": [
            200,
            663,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 9999,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "chopMutation",
          "presentation": 0,
          "presentation_rect": [
            200,
            663,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Chop variation",
              "parameter_shortname": "Chop variation",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 9999,
              "parameter_initial": [
                0
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "prechopMutation",
          "maxclass": "newobj",
          "patching_rect": [
            560,
            740,
            170,
            22
          ],
          "text": "prepend param chopMutation"
        }
      },
      {
        "box": {
          "id": "drumMutation",
          "maxclass": "live.numbox",
          "patching_rect": [
            300,
            663,
            67,
            16
          ],
          "minimum": 0,
          "maximum": 9999,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "drumMutation",
          "presentation": 0,
          "presentation_rect": [
            300,
            663,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Drum variation",
              "parameter_shortname": "Drum variation",
              "parameter_type": 0,
              "parameter_mmin": 0,
              "parameter_mmax": 9999,
              "parameter_initial": [
                0
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "predrumMutation",
          "maxclass": "newobj",
          "patching_rect": [
            740,
            740,
            170,
            22
          ],
          "text": "prepend param drumMutation"
        }
      },
      {
        "box": {
          "id": "drumChopSeed",
          "maxclass": "live.numbox",
          "patching_rect": [
            400,
            663,
            67,
            16
          ],
          "minimum": 1,
          "maximum": 9999,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "drumChopSeed",
          "presentation": 0,
          "presentation_rect": [
            400,
            663,
            67,
            16
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Anchor seed",
              "parameter_shortname": "Anchor seed",
              "parameter_type": 0,
              "parameter_mmin": 1,
              "parameter_mmax": 9999,
              "parameter_initial": [
                1729
              ],
              "parameter_initial_enable": 1,
              "parameter_unitstyle": 0
            }
          }
        }
      },
      {
        "box": {
          "id": "predrumChopSeed",
          "maxclass": "newobj",
          "patching_rect": [
            200,
            770,
            170,
            22
          ],
          "text": "prepend param drumChopSeed"
        }
      },
      {
        "box": {
          "id": "lockChops",
          "maxclass": "live.text",
          "patching_rect": [
            5,
            113,
            67,
            14
          ],
          "text": "Lock chops",
          "texton": "Lock chops",
          "mode": 1,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "lockChops",
          "presentation": 1,
          "presentation_rect": [
            5,
            113,
            67,
            14
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Lock chops",
              "parameter_shortname": "Lock chops",
              "parameter_type": 2,
              "parameter_enum": [
                "Off",
                "On"
              ],
              "parameter_initial": [
                0
              ],
              "parameter_initial_enable": 1
            }
          }
        }
      },
      {
        "box": {
          "id": "prelockChops",
          "maxclass": "newobj",
          "patching_rect": [
            550,
            710,
            170,
            22
          ],
          "text": "prepend param lockChops"
        }
      },
      {
        "box": {
          "id": "lockDrums",
          "maxclass": "live.text",
          "patching_rect": [
            79,
            113,
            67,
            14
          ],
          "text": "Lock drums",
          "texton": "Lock drums",
          "mode": 1,
          "numinlets": 1,
          "numoutlets": 2,
          "parameter_enable": 1,
          "varname": "lockDrums",
          "presentation": 1,
          "presentation_rect": [
            79,
            113,
            67,
            14
          ],
          "saved_attribute_attributes": {
            "valueof": {
              "parameter_longname": "Lock drums",
              "parameter_shortname": "Lock drums",
              "parameter_type": 2,
              "parameter_enum": [
                "Off",
                "On"
              ],
              "parameter_initial": [
                0
              ],
              "parameter_initial_enable": 1
            }
          }
        }
      },
      {
        "box": {
          "id": "prelockDrums",
          "maxclass": "newobj",
          "patching_rect": [
            730,
            710,
            170,
            22
          ],
          "text": "prepend param lockDrums"
        }
      },
      {
        "box": {
          "id": "buttonfresh",
          "maxclass": "textbutton",
          "patching_rect": [
            5,
            130,
            67,
            16
          ],
          "text": "NEW",
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 3,
          "presentation": 1,
          "presentation_rect": [
            5,
            130,
            67,
            16
          ],
          "fontsize": 10
        }
      },
      {
        "box": {
          "id": "selfresh",
          "maxclass": "newobj",
          "patching_rect": [
            600,
            590,
            45,
            22
          ],
          "text": "sel 1"
        }
      },
      {
        "box": {
          "id": "msgfresh",
          "maxclass": "message",
          "patching_rect": [
            600,
            620,
            60,
            22
          ],
          "text": "fresh"
        }
      },
      {
        "box": {
          "id": "buttonmutate",
          "maxclass": "textbutton",
          "patching_rect": [
            79,
            130,
            67,
            16
          ],
          "text": "VARY",
          "mode": 0,
          "numinlets": 1,
          "numoutlets": 3,
          "presentation": 1,
          "presentation_rect": [
            79,
            130,
            67,
            16
          ],
          "fontsize": 10
        }
      },
      {
        "box": {
          "id": "selmutate",
          "maxclass": "newobj",
          "patching_rect": [
            700,
            590,
            45,
            22
          ],
          "text": "sel 1"
        }
      },
      {
        "box": {
          "id": "msgmutate",
          "maxclass": "message",
          "patching_rect": [
            700,
            620,
            60,
            22
          ],
          "text": "mutate"
        }
      },
      {
        "box": {
          "id": "route",
          "maxclass": "newobj",
          "patching_rect": [
            350,
            555,
            500,
            22
          ],
          "text": "route chopSeed drumSeed chopMutation drumMutation drumChopSeed"
        }
      },
      {
        "box": {
          "id": "setchopSeed",
          "maxclass": "newobj",
          "patching_rect": [
            900,
            0,
            80,
            22
          ],
          "text": "prepend set"
        }
      },
      {
        "box": {
          "id": "setdrumSeed",
          "maxclass": "newobj",
          "patching_rect": [
            900,
            40,
            80,
            22
          ],
          "text": "prepend set"
        }
      },
      {
        "box": {
          "id": "setchopMutation",
          "maxclass": "newobj",
          "patching_rect": [
            900,
            80,
            80,
            22
          ],
          "text": "prepend set"
        }
      },
      {
        "box": {
          "id": "setdrumMutation",
          "maxclass": "newobj",
          "patching_rect": [
            900,
            120,
            80,
            22
          ],
          "text": "prepend set"
        }
      },
      {
        "box": {
          "id": "setdrumChopSeed",
          "maxclass": "newobj",
          "patching_rect": [
            900,
            160,
            80,
            22
          ],
          "text": "prepend set"
        }
      },
      {
        "box": {
          "id": "line",
          "maxclass": "live.line",
          "patching_rect": [
            0,
            146,
            152,
            1
          ],
          "presentation": 1,
          "presentation_rect": [
            0,
            146,
            152,
            1
          ]
        }
      }
    ],
    "lines": [
      {
        "patchline": {
          "source": [
            "in",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "engine",
            0
          ],
          "destination": [
            "out",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "engine",
            3
          ],
          "destination": [
            "in",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "chopSeed",
            0
          ],
          "destination": [
            "prechopSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prechopSeed",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "drumSeed",
            0
          ],
          "destination": [
            "predrumSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "predrumSeed",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "repeat",
            0
          ],
          "destination": [
            "prerepeat",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prerepeat",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "change",
            0
          ],
          "destination": [
            "prechange",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prechange",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "feel",
            0
          ],
          "destination": [
            "prefeel",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prefeel",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "density",
            0
          ],
          "destination": [
            "predensity",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "predensity",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "chopMutation",
            0
          ],
          "destination": [
            "prechopMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prechopMutation",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "drumMutation",
            0
          ],
          "destination": [
            "predrumMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "predrumMutation",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "drumChopSeed",
            0
          ],
          "destination": [
            "predrumChopSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "predrumChopSeed",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "lockChops",
            0
          ],
          "destination": [
            "prelockChops",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prelockChops",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "lockDrums",
            0
          ],
          "destination": [
            "prelockDrums",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "prelockDrums",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "buttonfresh",
            0
          ],
          "destination": [
            "msgfresh",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msgfresh",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "buttonmutate",
            0
          ],
          "destination": [
            "msgmutate",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "msgmutate",
            0
          ],
          "destination": [
            "engine",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "engine",
            1
          ],
          "destination": [
            "route",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "route",
            0
          ],
          "destination": [
            "setchopSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "setchopSeed",
            0
          ],
          "destination": [
            "chopSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "route",
            1
          ],
          "destination": [
            "setdrumSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "setdrumSeed",
            0
          ],
          "destination": [
            "drumSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "route",
            2
          ],
          "destination": [
            "setchopMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "setchopMutation",
            0
          ],
          "destination": [
            "chopMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "route",
            3
          ],
          "destination": [
            "setdrumMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "setdrumMutation",
            0
          ],
          "destination": [
            "drumMutation",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "route",
            4
          ],
          "destination": [
            "setdrumChopSeed",
            0
          ]
        }
      },
      {
        "patchline": {
          "source": [
            "setdrumChopSeed",
            0
          ],
          "destination": [
            "drumChopSeed",
            0
          ]
        }
      }
    ],
    "dependency_cache": [],
    "latency": 0,
    "is_mpe": 0,
    "minimum_live_version": "12.0",
    "minimum_max_version": "9.0",
    "platform_compatibility": 0,
    "project": {
      "version": 1,
      "creationdate": 3590052493,
      "modificationdate": 3590052493,
      "viewrect": [
        25,
        124,
        300,
        500
      ],
      "autoorganize": 1,
      "hideprojectwindow": 1,
      "showdependencies": 1,
      "autolocalize": 0,
      "contents": {
        "patchers": {}
      },
      "layout": {},
      "searchpath": {},
      "detailsvisible": 0,
      "amxdtype": 1851877223,
      "readonly": 0,
      "devpathtype": 0,
      "devpath": ".",
      "sortmode": 0,
      "viewmode": 0,
      "includepackages": 0
    },
    "autosave": 0,
    "saved_attribute_attributes": {
      "default_plcolor": {
        "expression": ""
      }
    },
    "bgcolor": [
      0.12,
      0.13,
      0.15,
      1
    ],
    "parameters": {
      "chopSeed": [
        "Chop seed",
        "Chop seed",
        0
      ],
      "drumSeed": [
        "Drum seed",
        "Drum seed",
        0
      ],
      "repeat": [
        "Repeat",
        "Repeat",
        0
      ],
      "change": [
        "Change",
        "Change",
        0
      ],
      "feel": [
        "Feel",
        "Feel",
        0
      ],
      "density": [
        "Density",
        "Density",
        0
      ],
      "chopMutation": [
        "Chop variation",
        "Chop variation",
        0
      ],
      "drumMutation": [
        "Drum variation",
        "Drum variation",
        0
      ],
      "drumChopSeed": [
        "Anchor seed",
        "Anchor seed",
        0
      ],
      "lockChops": [
        "Lock chops",
        "Lock chops",
        0
      ],
      "lockDrums": [
        "Lock drums",
        "Lock drums",
        0
      ]
    }
  }
}