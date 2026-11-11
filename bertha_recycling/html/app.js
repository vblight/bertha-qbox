const panel=document.getElementById('panel');const $=id=>document.getElementById(id);let state={},capacity=12,outputCapacity=240,per=4,carrying=false,quantity=1,rollQuantity=1,perRoll=10,rollCapacity=24,open=false;let machineLevel=0,machineVolume=.20,machineRunning=false,plasticQuantity=1,pelletQuantity=1,plasticCapacity=240,plasticPerPellet=2,plasticOutputCapacity=240,inventoryPlastic=0,inventoryTyres=0,inventoryRubber=0,inventoryGlass=0,glassCapacity=160,glassOutputCapacity=20,glassPerSheet=8;
let times={rubber:12000,roll:20000,pellets:25000,glass:60000};
const resource=GetParentResourceName();
const machineAudio = new Audio('machinery-hum.mp3');
machineAudio.loop = true;
machineAudio.preload = 'auto';
let audioUnlocked = false;
let playPending = false;
let pendingStart = false;
function tryPlayMotor() {
  if (playPending || !machineAudio.paused) return;
  playPending = true;
  const promise = machineAudio.play();
  if (promise && promise.then) promise.then(() => { playPending = false; }).catch(() => { playPending = false; });
  else playPending = false;
}
function unlockMotor() {
  audioUnlocked = true;
  pendingStart = true;
  machineAudio.loop = true;
  machineAudio.volume = Math.max(0.01, userVolume * 0.8);
  tryPlayMotor();
  sound();
}
machineAudio.addEventListener('ended', () => {
  if (machineRunning || pendingStart) { machineAudio.currentTime = 0; tryPlayMotor(); }
});
machineAudio.addEventListener('error', () => console.warn('[Big Bertha] Motor audio failed to load'));
let userVolume=Number(localStorage.getItem('berthaVolume')??70)/100;
userVolume=Math.max(0,Math.min(1,userVolume));
function post(action,quantity=1){fetch(`https://${resource}/action`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({action,quantity})}).catch(()=>{});}
function close(){open=false;panel.classList.add('hidden');sound();fetch(`https://${resource}/close`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).catch(()=>{});}
function sound() {
  const shouldPlay = machineRunning || pendingStart;
  const v = Math.max(0, Math.min(1, machineVolume * machineLevel * userVolume * 3));
  machineAudio.volume = shouldPlay ? (pendingStart && !machineRunning ? Math.max(0.01,userVolume*0.8) : v) : 0;
  if (shouldPlay) {
    if (audioUnlocked) { machineAudio.loop=true; tryPlayMotor(); }
  } else {
    if (!machineAudio.paused) machineAudio.pause();
    if (machineAudio.currentTime) machineAudio.currentTime = 0;
  }
}
// Restart audio if FiveM's NUI browser suspends playback mid-batch.
setInterval(() => {
  if ((machineRunning || pendingStart) && audioUnlocked) {
    machineAudio.loop = true;
    if (machineAudio.ended) machineAudio.currentTime = 0;
    if (machineAudio.paused) tryPlayMotor();
  }
}, 500);
function maxPellets(){return Math.max(0,Math.min(Math.floor((Number(state.plasticScraps)||0)/plasticPerPellet),plasticOutputCapacity-(Number(state.plasticPellets)||0)))}
function setNumber(id,n,max){if(document.activeElement!==$(id))$(id).value=String(Math.max(1,Math.min(max,Math.floor(Number(n)||1))))}
function readNumbers(){quantity=Math.max(1,Math.min(capacity,Math.floor(Number($('quantity').value)||1)));rollQuantity=Math.max(1,Math.min(rollCapacity,Math.floor(Number($('rollquantity').value)||1)));plasticQuantity=Math.max(1,Math.min(plasticCapacity,Math.floor(Number($('plasticquantity').value)||1)));pelletQuantity=Math.max(1,Math.min(plasticOutputCapacity,Math.floor(Number($('pelletquantity').value)||1)))}
function renderGlass(){
 const chunks=Number(state.glassChunks)||0,sheets=Number(state.glassSheets)||0;
 const reserved=Number(state.reservedGlassSheets)||0;
 const load=Math.max(0,Math.floor(Number($('glassloadquantity').value)||0));
 const craft=Math.max(1,Math.floor(Number($('glassquantity').value)||1));
 $('glasschunks').textContent=chunks;$('glasscap').textContent=glassCapacity;
 $('glasspockets').textContent=inventoryGlass;
 $('glasssheets').textContent=sheets;$('glassoutputcap').textContent=glassOutputCapacity;
 $('depositGlass').disabled=load<1||load>inventoryGlass||chunks+load>glassCapacity;
 $('withdrawGlass').disabled=load<1||load>chunks;
 $('makeGlass').disabled=craft>Math.floor(chunks/glassPerSheet)||sheets+reserved+craft>glassOutputCapacity;
 $('collectGlass').disabled=sheets<1;
 $('glassrequirements').textContent='Needs '+(craft*glassPerSheet)+' glass chunks · '+(craft*times.glass/1000)+'s · '+Math.min(Math.floor(chunks/glassPerSheet),Math.max(0,glassOutputCapacity-sheets-reserved))+' craftable';
}
function renderQueue(){
  const jobs=Array.isArray(state.queue)?state.queue:[];
  const names={rubber:'Tires → Rubber',rubberRoll:'Rubber → Rolls',plasticPellets:'Plastic → Pellets',glassSheets:'Glass → Sheets'};
  $('queue').textContent=jobs.length+' waiting'+(state.running?' · 1 active':'');
  const el=$('queueList');el.replaceChildren();
  const items=[];
  if(state.running)items.push({recipe:state.recipe,batch:state.batch,active:true});
  for(const j of jobs)items.push({...j,active:false});
  if(!items.length){const e=document.createElement('span');e.className='muted';e.textContent='No jobs waiting — add a recipe to begin.';el.appendChild(e);}
  items.forEach((j,i)=>{const e=document.createElement('div');e.className='queue-job';
    const t=document.createElement('span');t.textContent=(j.active?'● RUNNING':'#'+(i+(state.running?0:1))+' WAITING')+' · '+(names[j.recipe]||j.recipe)+' · '+j.batch+' craft(s)';e.appendChild(t);
    const duration=Math.ceil(j.batch*(times[j.recipe==='rubberRoll'?'roll':j.recipe==='plasticPellets'?'pellets':j.recipe==='glassSheets'?'glass':'rubber']||12000)/1000);
    const d=document.createElement('small');d.textContent=j.active?'In progress':duration+'s';e.appendChild(d);el.appendChild(e);
  });
  for(let i=items.length;i<20;i++){const e=document.createElement('div');e.className='queue-job empty';e.textContent='Slot '+(i+1)+' · Free';el.appendChild(e);}
}
function render(){renderGlass();const intake=Number(state.intake)||0,output=Number(state.output)||0,running=!!state.running;quantity=Math.max(1,Math.min(quantity,capacity));const rolls=Number(state.rolls)||0;rollQuantity=Math.max(1,Math.min(rollQuantity,rollCapacity));setNumber('rollquantity',rollQuantity,rollCapacity);const scraps=Number(state.plasticScraps)||0,pellets=Number(state.plasticPellets)||0;$('scraps').textContent=scraps;$('plasticpockets').textContent='In pockets: '+inventoryPlastic;$('pellets').textContent=pellets;if(inventoryPlastic===0&&plasticQuantity===0&&document.activeElement!==$('plasticquantity'))$('plasticquantity').value='0';else setNumber('plasticquantity',plasticQuantity,plasticCapacity);setNumber('pelletquantity',pelletQuantity,plasticOutputCapacity);$('pelletrequirements').textContent='Needs '+(pelletQuantity*plasticPerPellet)+' plastic scraps · '+Math.floor(pelletQuantity*(times.pellets||25000)/1000)+'s · '+maxPellets()+' craftable';$('depositPlastic').disabled=inventoryPlastic<=0||plasticQuantity<=0||plasticQuantity>inventoryPlastic||scraps+plasticQuantity>plasticCapacity;$('withdrawPlastic').disabled=scraps<plasticQuantity;$('makePellets').disabled=scraps<pelletQuantity*plasticPerPellet||pellets+pelletQuantity+(Number(state.reservedPellets)||0)>plasticOutputCapacity;$('collectPellets').disabled=pellets<=0;$('rubberpockets').textContent=inventoryRubber;$('rubberstored').textContent=output;
const rubberRequest=Math.max(0,Math.floor(Number($('rubberloadquantity').value)||0));
$('depositRubber').disabled=rubberRequest<1||rubberRequest>inventoryRubber||output+rubberRequest+(Number(state.reservedRubber)||0)>outputCapacity;
$('rolls').textContent=rolls;$('rollcap').textContent=rollCapacity;$('makerolls').disabled=output<perRoll*rollQuantity||rolls+rollQuantity+(Number(state.reservedRolls)||0)>rollCapacity;$('collectrolls').disabled=rolls<=0;$('intake').textContent=intake;$('cap').textContent=capacity;$('output').textContent=output;$('outputcap').textContent='/ '+outputCapacity;$('per').textContent=per;setNumber('quantity',quantity,capacity);$('status').textContent=running?'PROCESSING':'IDLE';$('status').style.color=running?'#ffffff':'#c3c3c8';$('carry').textContent=carrying?'CARRYING ONE TIRE':'NOT CARRYING A TIRE';renderQueue();$('deposit').disabled=!carrying||intake>=capacity;const tyreInput=$('tyreinventoryquantity');const requested=Math.max(0,Math.floor(Number(tyreInput.value)||0));$('tyreinventoryavailable').textContent='Inventory: '+inventoryTyres+' used tires';$('depositInventoryTyres').disabled=requested<=0||inventoryTyres<requested||intake+requested>capacity;$('withdraw').disabled=carrying||intake<=0;$('start').disabled=intake<quantity||output+quantity*per+(Number(state.reservedRubber)||0)>outputCapacity;$('collect').disabled=output<=0;$('minus').disabled=quantity<=1;$('plus').disabled=quantity>=intake;const slots=$('slots');slots.replaceChildren();for(let i=0;i<capacity;i++){const cell=document.createElement('i');if(i<intake)cell.className='full';slots.appendChild(cell)}let remain=running?Math.max(0,(Number(state.finishAt)||0)-Date.now()/1000):0;let total=(Number(state.batch)||1)*(times[({rubberRoll:'roll',plasticPellets:'pellets',glassSheets:'glass'})[state.recipe]||state.recipe]||times.rubber)/1000;$('progress').style.width=running?Math.max(0,Math.min(100,(1-remain/total)*100))+'%':'0%';$('remaining').textContent=running?'Processing · '+Math.ceil(remain)+'s remaining':'Ready for processing';sound()}window.addEventListener('message',e=>{const d=e.data;if(d.type==='open'){open=true;capacity=d.capacity||12;outputCapacity=d.outputCapacity||240;per=d.perTyre||4;perRoll=d.perRoll||10;rollCapacity=d.rollCapacity||24;plasticCapacity=d.plasticCapacity||240;plasticOutputCapacity=d.plasticOutputCapacity||240;plasticPerPellet=d.plasticPerPellet||2;inventoryPlastic=Number(d.inventoryPlastic)||0;inventoryTyres=Number(d.inventoryTyres)||0;inventoryRubber=Number(d.inventoryRubber)||0;inventoryGlass=Number(d.inventoryGlass)||0;glassCapacity=d.glassCapacity||160;glassOutputCapacity=d.glassOutputCapacity||20;glassPerSheet=d.glassPerSheet||8;times=d.times||times;state=d.state||{};carrying=!!d.carrying;panel.classList.remove('hidden');render()}else if(d.type==='state'){state=d.state||{};carrying=!!d.carrying;inventoryPlastic=Number(d.inventoryPlastic)||0;inventoryTyres=Number(d.inventoryTyres)||0;inventoryRubber=Number(d.inventoryRubber)||0;inventoryGlass=Number(d.inventoryGlass)||0;if(open)render()}else if(d.type==='machineAudio'){machineRunning=!!d.running;if(machineRunning)pendingStart=false;else if(pendingStart){setTimeout(()=>{if(!machineRunning){pendingStart=false;sound()}},1800)};machineLevel=Math.max(0,Math.min(1,Number(d.level)||0));machineVolume=Math.max(0,Math.min(1,Number(d.volume ?? .20)));sound()}else if(d.type==='close'){open=false;panel.classList.add('hidden');sound()}});document.addEventListener('pointerdown',()=>{audioUnlocked=true;if(machineRunning||pendingStart)tryPlayMotor();sound();});$('volume').value=Math.round(userVolume*100);$('volumeValue').textContent=Math.round(userVolume*100)+'%';$('volume').oninput=()=>{userVolume=Number($('volume').value)/100;$('volumeValue').textContent=Math.round(userVolume*100)+'%';localStorage.setItem('berthaVolume',String(Math.round(userVolume*100)));sound()};$('close').onclick=close;document.addEventListener('keydown',e=>{if(e.key==='Escape'&&open)close()});$('deposit').onclick=()=>post('deposit');$('withdraw').onclick=()=>post('withdraw');$('start').onclick=()=>{readNumbers();if(!state.running)unlockMotor();post('start',quantity)};$('collect').onclick=()=>post('collect');$('makerolls').onclick=()=>{readNumbers();if(!state.running)unlockMotor();post('makeRolls',rollQuantity)};$('collectrolls').onclick=()=>post('collectRolls');$('rollminus').onclick=()=>{rollQuantity=Math.max(1,rollQuantity-1);render()};$('rollplus').onclick=()=>{rollQuantity=Math.min(Math.max(1,Math.floor((Number(state.output)||0)/perRoll)),Math.max(1,rollCapacity-(Number(state.rolls)||0)),rollQuantity+1);render()};$('minus').onclick=()=>{quantity=Math.max(1,quantity-1);render()};$('plus').onclick=()=>{quantity=Math.min(Math.max(1,Number(state.intake)||1),quantity+1);render()};setInterval(()=>{if(open)render()},1000);
$('plasticminus').onclick=()=>{plasticQuantity=Math.max(1,plasticQuantity-1);render()};
$('plasticplus').onclick=()=>{plasticQuantity=Math.min(plasticCapacity,plasticQuantity+1);render()};
for(const action of ['depositPlastic','withdrawPlastic','makePellets'])$(action).onclick=()=>{readNumbers();if(action==='makePellets'&&!state.running){unlockMotor();}post(action,action==='makePellets'?pelletQuantity:plasticQuantity)};
$('collectPellets').onclick=()=>post('collectPellets');

// Editable quantities, separate transfer and crafting controls, and explicit MAX buttons.
for(const [id,key,max] of [['quantity','quantity',()=>capacity],['rollquantity','rollQuantity',()=>rollCapacity],['plasticquantity','plasticQuantity',()=>plasticCapacity],['pelletquantity','pelletQuantity',()=>plasticOutputCapacity]]){
  $(id).addEventListener('input',()=>{const n=Math.floor(Number($(id).value));if(Number.isFinite(n)&&n>=1){if(key==='quantity')quantity=n;else if(key==='rollQuantity')rollQuantity=n;else if(key==='plasticQuantity')plasticQuantity=n;else pelletQuantity=n;render();}});
  $(id).addEventListener('change',()=>{readNumbers();render()});
}
$('plasticmax').onclick=()=>{plasticQuantity=Math.max(0,Math.min(inventoryPlastic,plasticCapacity-(Number(state.plasticScraps)||0)));$('plasticquantity').value=String(plasticQuantity);render()};
$('pelletmax').onclick=()=>{pelletQuantity=Math.max(1,maxPellets());render()};
$('tyremax').onclick=()=>{quantity=Math.max(1,Math.min(Number(state.intake)||0,Math.floor((outputCapacity-(Number(state.output)||0))/per)));render()};
$('rollmax').onclick=()=>{rollQuantity=Math.max(1,Math.min(Math.floor((Number(state.output)||0)/perRoll),rollCapacity-(Number(state.rolls)||0)));render()};
$('pelletminus').onclick=()=>{pelletQuantity=Math.max(1,pelletQuantity-1);render()};
$('pelletplus').onclick=()=>{pelletQuantity=Math.min(plasticOutputCapacity,pelletQuantity+1);render()};

// Recipe tabs change only the view; server-side queue and inventory remain authoritative.
for(const tab of document.querySelectorAll('.recipe-tab'))tab.addEventListener('click',()=>{
 for(const t of document.querySelectorAll('.recipe-tab'))t.classList.toggle('active',t===tab);
 for(const d of document.querySelectorAll('.recipe-detail'))d.classList.toggle('hidden',d.dataset.detail!==tab.dataset.recipe);
});

$('tyreinventoryquantity').addEventListener('input',()=>{if(open)render()});
$('tyreinventorymax').onclick=()=>{$('tyreinventoryquantity').value=Math.max(0,Math.min(inventoryTyres,capacity-(Number(state.intake)||0)));render()};
$('depositInventoryTyres').onclick=()=>{const n=Math.floor(Number($('tyreinventoryquantity').value)||0);if(n>0)fetch(`https://${resource}/depositInventoryTyres`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({quantity:n})}).then(r=>{if(!r.ok)throw Error('NUI callback unavailable');return r.json()}).catch(err=>{console.error('[Big Bertha] Inventory tire transfer failed:',err);alert('Tire transfer failed. Check F8 for details.')})};

// Rubber can be supplied from qb-inventory independently of tire shredding.
$('rubberloadmax').onclick=()=>{
  const room=Math.max(0,outputCapacity-(Number(state.output)||0)-(Number(state.reservedRubber)||0));
  $('rubberloadquantity').value=String(Math.min(inventoryRubber,room));
  render();
};
$('rubberloadquantity').addEventListener('input',render);
$('depositRubber').onclick=()=>{
  const amount=Math.floor(Number($('rubberloadquantity').value)||0);
  if(amount>0&&amount<=inventoryRubber)post('depositRubber',amount);
};

// Glass intake, crafting and output; all transfers are checked server-side.
$('glassloadmax').onclick=()=>{
 const room=Math.max(0,glassCapacity-(Number(state.glassChunks)||0));
 $('glassloadquantity').value=String(Math.min(room,inventoryGlass));render();
};
$('glassmax').onclick=()=>{
 const room=Math.max(0,glassOutputCapacity-(Number(state.glassSheets)||0)-(Number(state.reservedGlassSheets)||0));
 $('glassquantity').value=String(Math.max(1,Math.min(room,Math.floor((Number(state.glassChunks)||0)/glassPerSheet))));render();
};
$('glassloadquantity').addEventListener('input',render);
$('glassquantity').addEventListener('input',render);
$('depositGlass').onclick=()=>post('depositGlass',Math.floor(Number($('glassloadquantity').value)||0));
$('withdrawGlass').onclick=()=>post('withdrawGlass',Math.floor(Number($('glassloadquantity').value)||0));
$('makeGlass').onclick=()=>{if(!state.running)unlockMotor();post('makeGlass',Math.floor(Number($('glassquantity').value)||0))};
$('collectGlass').onclick=()=>post('collectGlass');
