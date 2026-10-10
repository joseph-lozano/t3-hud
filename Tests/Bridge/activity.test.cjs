const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const script = fs.readFileSync('Resources/ActivityBridge.js', 'utf8');
function fixture(stored={}) {
 const messages=[];
 class Socket extends EventTarget {
  constructor(url){super();this.url=url;this.sent=[];}
  send(data){this.sent.push(data);}
  receive(message){const event=new Event('message');event.data=JSON.stringify(message);this.dispatchEvent(event);}
  close(){this.dispatchEvent(new Event('close'));}
 }
 const win={WebSocket:Socket,fetch:()=>Promise.resolve({ok:true,clone:()=>({json:()=>Promise.resolve({snapshotSequence:1,threads:[thread('http','running')]})})}),localStorage:Object.assign(Object.create({getItem(k){return this.items[k]??null;},setItem(k,v){this.items[k]=String(v);}}),{items:{'t3code:ui-state:v1':JSON.stringify({threadLastVisitedAtById:stored})}}),webkit:{messageHandlers:{t3HudNotifications:{postMessage:m=>messages.push(m)}}}};
 win.top=win;
 vm.runInNewContext(script,{window:win,location:{origin:'https://app.t3.codes',hostname:'app.t3.codes',href:'https://app.t3.codes/'},URL,ArrayBuffer,TextDecoder});
 return {win,messages,working:()=>messages.at(-1).working,done:()=>messages.at(-1).done, socket:(host='server')=>{const s=new win.WebSocket(`wss://${host}/ws?wsTicket=SECRET`);s.send(JSON.stringify({_tag:'Request',id:'1',tag:'orchestration.subscribeShell'}));return s;}};
}
function thread(id,status,extra={}){return {id,session:{status},...extra};}
function chunk(s,...values){s.receive({_tag:'Chunk',requestId:'1',values});}
function snapshot(s,threads,n=1){chunk(s,{kind:'snapshot',snapshot:{snapshotSequence:n,threads}});}
function upsert(s,t,n){chunk(s,{kind:'thread-upserted',sequence:n,thread:t});}
test('starts idle; aggregates threads and environments; completion does not clear other work',()=>{
 const f=fixture();assert.equal(f.working(),false);
 const a=f.socket('a'),b=f.socket('b');snapshot(a,[thread('1','running'),thread('2','starting')]);snapshot(b,[thread('1','running')]);
 assert.equal(f.working(),true);upsert(a,thread('1','ready'),2);upsert(a,thread('2','ready'),3);assert.equal(f.working(),true);
 b.close();assert.equal(f.working(),false);
 assert.ok(f.messages.every(m=>['op,working','done,op,working'].includes(Object.keys(m).sort().join(','))));
});
test('ignores stale updates, unrelated streams and malformed messages; removes finished and archived work',()=>{
 const f=fixture(),s=f.socket();snapshot(s,[thread('1','running')],5);upsert(s,thread('1','ready'),4);assert.equal(f.working(),true);
 s.receive({_tag:'Chunk',requestId:'other',values:[{kind:'thread-removed',sequence:10,threadId:'1'}]});assert.equal(f.working(),true);
 s.receive(null);upsert(s,thread('1','running',{archivedAt:'now'}),6);assert.equal(f.working(),false);
 upsert(s,thread('2','running'),7);chunk(s,{kind:'thread-removed',sequence:8,threadId:'2'});assert.equal(f.working(),false);
});
test('approval, input, error and monitoring do not animate; background working does',()=>{
 const f=fixture(),s=f.socket();
 snapshot(s,[thread('1','running',{hasPendingApprovals:true}),thread('2','running',{hasPendingUserInput:true}),thread('3','error',{backgroundLiveness:'working'}),thread('4','ready',{backgroundLiveness:'monitoring'})]);assert.equal(f.working(),false);
 upsert(s,thread('5','ready',{backgroundLiveness:'working'}),2);assert.equal(f.working(),true);
 s.receive({_tag:'Exit',requestId:'1'});assert.equal(f.working(),false);
});
test('HTTP snapshot seeds socket, preserves fetch response, and updates cache on completion before reconnect',async()=>{
 const f=fixture();const result=await f.win.fetch('https://server/api/orchestration/shell');assert.equal(result.ok,true);
 await new Promise(resolve=>setImmediate(resolve));assert.equal(f.working(),false);
 const s=f.socket();assert.equal(f.working(),true);upsert(s,thread('http','ready'),2);assert.equal(f.working(),false);s.close();
 f.socket();assert.equal(f.working(),false);
});
test('unsubscribing clears activity and native send still receives exact request',()=>{
 const f=fixture(),s=f.socket();snapshot(s,[thread('1','running')]);const value=JSON.stringify({_tag:'Interrupt',requestId:'1'});s.send(value);assert.equal(s.sent.at(-1),value);assert.equal(f.working(),false);
});
function v2(id,status,extra={}){return {id,status,latestRunId:'run',latestRunCompletedAt:null,pendingRuntimeRequest:null,updatedAt:'2026-10-09T10:00:00Z',archivedAt:null,deletedAt:null,...extra};}
function updated(s,t,n){chunk(s,{kind:'thread.updated',sequence:n,thread:t});}
test('nightly shells animate and count Done threads from server visits',()=>{
 const f=fixture(),s=f.socket();const done={latestRunCompletedAt:'2026-10-09T10:00:00Z',lastVisitedAt:'2026-10-09T09:00:00Z'};
 snapshot(s,[v2('1','completed',done),v2('2','completed',done),v2('3','completed',{...done,lastVisitedAt:'2026-10-09T11:00:00Z'}),
  v2('4','completed',{...done,lastVisitedAt:null}),v2('5','completed',{...done,archivedAt:'now'}),v2('6','failed',done),
  v2('7','completed',{...done,pendingRuntimeRequest:{kind:'approval'}}),v2('8','running')]);
 assert.equal(f.working(),true);assert.equal(f.done(),2);
 updated(s,v2('1','completed',{...done,lastVisitedAt:'2026-10-09T12:00:00Z'}),2);assert.equal(f.done(),1);
 updated(s,v2('8','completed',done),3);assert.equal(f.working(),false);assert.equal(f.done(),2);
 chunk(s,{kind:'thread.removed',sequence:4,threadId:'2'});assert.equal(f.done(),1);
 s.close();assert.equal(f.messages.at(-1).done,undefined);
});
test('stable shells use T3 local visits, which update on write',()=>{
 const f=fixture({'env:1':'2026-10-09T09:00:00Z','env:2':'2026-10-09T11:00:00Z'}),s=f.socket();
 snapshot(s,[thread('1','ready',{latestTurn:{completedAt:'2026-10-09T10:00:00Z'}}),thread('2','ready',{latestTurn:{completedAt:'2026-10-09T10:00:00Z'}}),
  thread('3','ready',{latestTurn:{completedAt:'2026-10-09T10:00:00Z'}}),thread('4','running',{latestTurn:{completedAt:'2026-10-09T10:00:00Z'}})]);
 assert.equal(f.done(),1);
 f.win.localStorage.setItem('t3code:ui-state:v1',JSON.stringify({threadLastVisitedAtById:{'env:1':'2026-10-09T12:00:00Z'}}));assert.equal(f.done(),0);
});
