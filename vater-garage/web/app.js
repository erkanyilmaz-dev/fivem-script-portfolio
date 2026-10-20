const app = document.querySelector('#app');
const list = document.querySelector('#vehicle-list');
const empty = document.querySelector('#empty-state');
const search = document.querySelector('#search');
const modal = document.querySelector('#transfer-modal');
let vehicles = [], activeFilter = 'all', selectedPlate = null;

const post = (name, data = {}) => fetch(`https://${GetParentResourceName()}/${name}`, {
  method: 'POST', headers: { 'Content-Type': 'application/json; charset=UTF-8' }, body: JSON.stringify(data)
});
const esc = value => String(value ?? '').replace(/[&<>'"]/g, char => ({ '&':'&amp;', '<':'&lt;', '>':'&gt;', "'":'&#39;', '"':'&quot;' }[char]));
const stateOf = vehicle => vehicle.state === 1 ? 'stored' : vehicle.state === 2 ? 'impound' : 'outside';
const stateLabel = state => ({ stored:'GARAJDA', outside:'DIŞARIDA', impound:'ÇEKİCİDE' }[state]);

function vehiclePhoto(vehicle) {
  const model = String(vehicle.vehicle || '').trim().toLowerCase();
  const customPhotos = {
    // Add-on cars use bundled local showroom images.
    rmodm4: 'assets/rmodm4.png',
    r8lms: 'assets/r8lms.png',
    '18performante': 'assets/18performante.png',
    gcmlamboultimae: 'assets/gcmlamboultimae.png'
  };
  return customPhotos[model] || `https://docs.fivem.net/vehicles/${encodeURIComponent(model)}.webp`;
}

function applyHeader(payload) {
  document.querySelector('#garage-name').textContent = payload.garage.label;
  document.querySelector('#garage-type').textContent = payload.garage.type === 'public' ? 'HALKA AÇIK' : payload.garage.type === 'job' ? 'MESLEK GARAJI' : 'ÇETE GARAJI';
}

function draw() {
  const needle = search.value.trim().toLocaleLowerCase('tr');
  const filtered = vehicles.filter(v => (activeFilter === 'all' || stateOf(v) === activeFilter) && (`${v.displayName} ${v.plate}`).toLocaleLowerCase('tr').includes(needle));
  document.querySelector('#stored-count').textContent = vehicles.filter(v => stateOf(v) === 'stored').length;
  document.querySelector('#outside-count').textContent = vehicles.filter(v => stateOf(v) === 'outside').length;
  list.innerHTML = filtered.map(v => {
    const state = stateOf(v);
    const health = Math.max(0, Math.min(100, Math.round((Number(v.engine) || 0) / 10)));
    const primaryAction = state === 'outside'
      ? `<button class="recover-button" data-action="recover" data-plate="${esc(v.plate)}">Geri al</button>`
      : `<button class="take-button" data-action="take" data-plate="${esc(v.plate)}">${state === 'impound' ? 'Çıkar' : 'Al'}</button>`;
    const fallback = esc((v.vehicle || v.displayName || 'CAR').slice(0, 2)).toUpperCase();
    return `<article class="vehicle-card"><div class="car-photo"><img src="${vehiclePhoto(v)}" alt="${esc(v.displayName)}" onerror="this.parentElement.classList.add('missing');this.remove()"><span>${fallback}</span></div><div><div class="vehicle-name">${esc(v.displayName)}</div><span class="plate">${esc(v.plate)}</span></div><div class="condition"><div class="condition-label"><span>MOTOR</span><b>%${health}</b></div><div class="condition-bar"><div class="condition-fill" style="width:${health}%"></div></div></div><div class="status ${state}"><i class="status-dot"></i>${stateLabel(state)}</div><div class="actions"><button class="star ${v.favorite ? 'active' : ''}" data-action="favorite" data-plate="${esc(v.plate)}">${v.favorite ? '★' : '☆'}</button><button class="transfer-item" data-action="transfer" data-plate="${esc(v.plate)}">↗</button>${primaryAction}</div></article>`;
  }).join('');
  empty.classList.toggle('hidden', filtered.length !== 0);
}

function close() { app.classList.add('hidden'); modal.classList.add('hidden'); post('close'); }
function openTransfer() {
  document.querySelector('#transfer-vehicle').textContent = selectedPlate
    ? `Seçilen araç: ${selectedPlate}`
    : 'Devretmek için araç listesinden bir plaka seç.';
  modal.classList.remove('hidden');
}

window.addEventListener('message', event => {
  if (event.data.action === 'open') {
    vehicles = event.data.payload.vehicles || [];
    applyHeader(event.data.payload);
    app.classList.remove('hidden');
    draw();
  }
  if (event.data.action === 'close') app.classList.add('hidden');
});
search.addEventListener('input', draw);
document.querySelectorAll('.filter').forEach(button => button.addEventListener('click', () => {
  activeFilter = button.dataset.filter;
  document.querySelectorAll('.filter').forEach(x => x.classList.toggle('active', x === button));
  draw();
}));
document.querySelector('#close-button').addEventListener('click', close);
document.addEventListener('keyup', event => { if (event.key === 'Escape') close(); });
list.addEventListener('click', event => {
  const button = event.target.closest('button[data-action]');
  if (!button || button.disabled) return;
  const plate = button.dataset.plate;
  const vehicle = vehicles.find(v => v.plate === plate);
  if (!vehicle) return;
  selectedPlate = plate;
  if (button.dataset.action === 'favorite') {
    vehicle.favorite = !vehicle.favorite;
    post('favorite', { plate, favorite: vehicle.favorite });
    draw();
  } else if (button.dataset.action === 'transfer') openTransfer();
  else if (button.dataset.action === 'recover') post('recover', { plate });
  else post('takeOut', { plate });
});
document.querySelector('#transfer-open').addEventListener('click', openTransfer);
document.querySelector('#transfer-close').addEventListener('click', () => modal.classList.add('hidden'));
document.querySelector('#transfer-form').addEventListener('submit', event => {
  event.preventDefault();
  if (!selectedPlate) return;
  const targetId = Number(document.querySelector('#target-id').value);
  if (!Number.isInteger(targetId) || targetId < 1) return;
  post('transfer', { plate: selectedPlate, targetId });
  modal.classList.add('hidden');
  document.querySelector('#target-id').value = '';
});

if (window.location.search.includes('preview')) {
  vehicles = [
    { plate:'WRATH 01', vehicle:'tenf2', displayName:'Obey 10F Widebody', state:1, engine:938, favorite:true },
    { plate:'VATER 77', vehicle:'comet6', displayName:'Pfister Comet S2', state:0, engine:780, favorite:false },
    { plate:'PVP 999', vehicle:'buffalo4', displayName:'Bravado Buffalo STX', state:2, engine:650, favorite:false }
  ];
  applyHeader({ garage:{ label:'Legion Square', type:'public' } });
  app.classList.remove('hidden');
  draw();
}
