var appname = 'giuliana';

window.onload = function()
{
  var route = PageAddress();
  if (route === 'login') { return; }
  var data = new FormData();
  data.append('page', route);
  Routing(data);
};
function SetAppIdItem(indexname, idvalue)
{
  localStorage.setItem(appname + '_' + indexname, idvalue);
};
function GetAppIdItem(indexname)
{
  return localStorage.getItem(appname + '_' + indexname);
};
function RemoveAppIdItem(indexname)
{
  localStorage.removeItem(appname + '_' + indexname);
};
async function Routing(data)
{
  try
  {
    let rawResponse = await fetch('./facades/Router.php', {
      method: 'POST',
      body: data
    });
    let content = await rawResponse.json();
    var hdr  = document.getElementById('header');
    var mcol = document.getElementById('maincol');
    if (content.res === 'no') { window.location.href = './login.html'; return; }
    if (hdr  && content.hr)  { hdr.innerHTML  = content.hr; }
    if (mcol && content.dom) { mcol.innerHTML = content.dom; }
    var page = data.get('page');
    switch(page)
    {
      case 'presenze':
        LoadFoglioGiornaliero();
      break;
      default:
      break;
    }
  }
  catch(error)
  {
    alert('errore: ' + error);
  };
};
async function Perform(data)
{
  var spin = document.getElementById('myspinner');
  if (spin) { spin.classList.remove('d-none'); }
  try
  {
    let rawResponse = await fetch('./facades/Performer.php',
    {
      method: 'POST',
      body: data
    });
    let content = await rawResponse.json();
    var action = data.get('action');
    if (content.res === 'no')
    {
      if (spin) { spin.classList.add('d-none'); }
      var openModal = document.querySelector('.modal.show');
      if (openModal)
      {
        openModal.querySelector('.modalalertmsg').textContent = content.msg;
        openModal.querySelector('.modalalert').classList.remove('d-none');
      }
      else
      {
        document.querySelector('#alertmsg').innerHTML = content.msg;
        new bootstrap.Collapse('#alert', {toggle: true});
      }
    }
    else
    {
      switch(action)
      {
        case 'login':
          location.href = content.dest || './dashboard.html';
        break;
        case 'logout':
          location.href = './login.html';
        break;
        case 'cantiere_create':
        case 'cantiere_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalCantiere');
        break;
        case 'operaio_create':
        case 'operaio_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalOperaio');
        break;
        case 'operaio_toggle':
          if (spin) { spin.classList.add('d-none'); }
          var opToggleRow = document.querySelector('.listrow[data-id="' + data.get('id') + '"]');
          if (opToggleRow)
          {
            var opToggleBtn  = opToggleRow.querySelector('.btnToggleOperaio');
            var opToggleIcon = opToggleBtn ? opToggleBtn.querySelector('i') : null;
            if (opToggleBtn && opToggleIcon)
            {
              var opNowActive = opToggleBtn.dataset.active !== '1';
              opToggleBtn.dataset.active = opNowActive ? '1' : '0';
              opToggleBtn.className = 'btn btn-sm btnToggleOperaio ' + (opNowActive ? 'btn-success' : 'btn-outline-secondary');
              opToggleIcon.className = 'bi ' + (opNowActive ? 'bi-toggle-on' : 'bi-toggle-off');
            }
          }
        break;
        case 'cliente_create':
        case 'cliente_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalCliente');
        break;
        case 'fornitore_create':
        case 'fornitore_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalFornitore');
        break;
        case 'presenza_upsert':
          if (spin) { spin.classList.add('d-none'); }
          var presRow = document.querySelector('.workercard[data-id-operaio="' + data.get('id_operaio') + '"]');
          if (presRow)
          {
            presRow.dataset.saved = '1';
            var saveIcon = presRow.querySelector('.iconsaved');
            if (saveIcon) { saveIcon.classList.remove('d-none'); }
          }
          UpdateDailyProgress();
        break;
        case 'foglio_giornaliero_save':
          if (spin) { spin.classList.add('d-none'); }
          var savedMsg = document.querySelector('.msgsaved');
          if (savedMsg) { savedMsg.classList.remove('d-none'); }
          setTimeout(function() { if (savedMsg) { savedMsg.classList.add('d-none'); } }, 2000);
        break;
        case 'settimana_chiudi':
          location.href = './presenze.html';
        break;
        case 'mezzo_create':
        case 'mezzo_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalMezzo');
        break;
        case 'materiale_create':
        case 'materiale_update':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalMateriale');
        break;
        case 'documento_create':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalDocumento');
        break;
        case 'attivita_gantt_upsert':
          if (spin) { spin.classList.add('d-none'); }
          CloseModalAndRefresh('modalAttivita');
        break;
        case 'evm_snapshot':
          if (spin) { spin.classList.add('d-none'); }
          var evmMsg = document.querySelector('.msgevm');
          if (evmMsg) { evmMsg.classList.remove('d-none'); }
        break;
        default:
          if (spin) { spin.classList.add('d-none'); }
        break;
      }
    }
  }
  catch(error)
  {
    alert('errore: ' + error);
  };
};
async function Compose(data)
{
  try
  {
    let rawResponse = await fetch('./facades/Composer.php', {
      method: 'POST',
      body: data
    });
    let content = await rawResponse.json();
    var compose = data.get('compose');
    if (content.res === 'no')
    {
      document.querySelector('#alertmsg').innerHTML = content.msg;
      new bootstrap.Collapse('#alert', {toggle: true});
    }
    else
    {
      switch(compose)
      {
        case 'foglio_giornaliero':
          var target = document.querySelector('.fogliowrapper');
          if (target) { target.innerHTML = content.dom; }
        break;
        case 'griglia_settimanale':
          var gTarget = document.querySelector('.grigliawrapper');
          if (gTarget) { gTarget.innerHTML = content.dom; }
        break;
        case 'operai_per_cantiere':
          var cmp = content.cmp;
          var opList = document.querySelector('.operailist');
          if (opList && cmp && cmp.rows)
          {
            opList.innerHTML = '';
            cmp.rows.forEach(function(op)
            {
              var li = document.createElement('li');
              li.className = 'list-group-item';
              li.dataset.value = op.id;
              li.textContent = op.cognome + ' ' + op.nome;
              opList.appendChild(li);
            });
          }
        break;
        case 'cantieri_attivi':
          var cmp = content.cmp;
          if (cmp && cmp.id_cantiere)
          {
            SetCustomSelect('srccantiere', 'cantiere', cmp.nome, cmp.id_cantiere);
          }
        break;
        case 'fornitori_per_categoria':
          var cmp = content.cmp;
          var fTarget = document.querySelector('.fornitorilist');
          if (fTarget && cmp && cmp.rows)
          {
            fTarget.innerHTML = '';
            cmp.rows.forEach(function(f)
            {
              var li = document.createElement('li');
              li.className = 'list-group-item';
              li.dataset.value = f.id;
              li.textContent = f.ragione_sociale;
              fTarget.appendChild(li);
            });
          }
        break;
        default:
        break;
      }
    }
  }
  catch(error)
  {
    alert('errore: ' + error);
  };
};
function PageAddress()
{
  var segment_str = window.location.pathname;
  var segment_array = segment_str.split('/');
  var last_segment = segment_array.pop();
  return last_segment.substr(0, last_segment.indexOf('.'));
};
function GetInputId(classname)
{
  var inputElement = document.querySelector('.' + classname);
  return inputElement ? inputElement.id : null;
};
function SetCustomSelect(srcClass, targetClass, displayText, idValue)
{
  document.querySelector('.' + srcClass).value = displayText;
  document.getElementById(GetInputId(targetClass)).value = idValue;
};
function CloseModalAndRefresh(modalId)
{
  var modalEl = document.getElementById(modalId);
  if (modalEl)
  {
    var modal = bootstrap.Modal.getInstance(modalEl);
    if (modal) { modal.hide(); }
  }
  var data = new FormData();
  data.append('page', PageAddress());
  Routing(data);
};
function OpenModalNew(modalId, titleText, resetFn)
{
  var modalEl = document.getElementById(modalId);
  if (!modalEl) { return; }
  var titleEl = modalEl.querySelector('.modaltitle');
  if (titleEl) { titleEl.textContent = titleText; }
  var alertEl = modalEl.querySelector('.modalalert');
  if (alertEl) { alertEl.classList.add('d-none'); }
  if (resetFn) { resetFn(modalEl); }
  var modal = bootstrap.Modal.getOrCreateInstance(modalEl);
  modal.show();
};
function SetVal(modalEl, selector, value)
{
  var el = modalEl.querySelector(selector);
  if (el) { el.value = value || ''; }
};
// ── MODAL OPEN FUNCTIONS ──────────────────────────────────────
function OpenNewCantiere()
{
  OpenModalNew('modalCantiere', 'Nuovo Cantiere', function(m) {
    SetVal(m, '.cantiereid', '');
    SetVal(m, '.cntnome', '');
    SetVal(m, '.cntcliente', '');
    SetVal(m, '.cntindirizzo', '');
    SetVal(m, '.cntdtstart', '');
    SetVal(m, '.cntdtend', '');
    SetVal(m, '.cntstato', '');
    SetVal(m, '.cntimporto', '');
    SetVal(m, '.cnttipo', '');
    SetVal(m, '.cntnote', '');
    m.querySelector('.btnSaveCantiere').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditCantiere(row)
{
  OpenModalNew('modalCantiere', 'Modifica Cantiere', function(m) {
    SetVal(m, '.cantiereid', row.dataset.id);
    SetVal(m, '.cntnome', row.dataset.nome);
    SetVal(m, '.cntcliente', row.dataset.idCliente);
    SetVal(m, '.cntindirizzo', row.dataset.indirizzo);
    SetVal(m, '.cntdtstart', row.dataset.dataInizio);
    SetVal(m, '.cntdtend', row.dataset.dataFine);
    SetVal(m, '.cntstato', row.dataset.stato);
    SetVal(m, '.cntimporto', row.dataset.importo);
    SetVal(m, '.cnttipo', row.dataset.tipo);
    SetVal(m, '.cntnote', row.dataset.note);
    CheckCantiereForm();
  });
};
function OpenNewOperaio()
{
  OpenModalNew('modalOperaio', 'Nuovo Operaio', function(m) {
    SetVal(m, '.operaioid', '');
    SetVal(m, '.opnome', '');
    SetVal(m, '.opcognome', '');
    SetVal(m, '.opcf', '');
    SetVal(m, '.optel', '');
    SetVal(m, '.opemail', '');
    SetVal(m, '.opdtnascita', '');
    SetVal(m, '.opdtassunzione', '');
    m.querySelector('.btnSaveOperaio').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditOperaio(row)
{
  OpenModalNew('modalOperaio', 'Modifica Operaio', function(m) {
    SetVal(m, '.operaioid', row.dataset.id);
    SetVal(m, '.opnome', row.dataset.nome);
    SetVal(m, '.opcognome', row.dataset.cognome);
    SetVal(m, '.opcf', row.dataset.cf);
    SetVal(m, '.optel', row.dataset.telefono);
    SetVal(m, '.opemail', row.dataset.email);
    SetVal(m, '.opdtnascita', row.dataset.dataNascita);
    SetVal(m, '.opdtassunzione', row.dataset.dataAssunzione);
    CheckOperaioForm();
  });
};
function OpenNewCliente()
{
  OpenModalNew('modalCliente', 'Nuovo Cliente', function(m) {
    SetVal(m, '.clienteid', '');
    SetVal(m, '.cltnome', '');
    SetVal(m, '.clttipo', '');
    SetVal(m, '.cltpiva', '');
    SetVal(m, '.cltcf', '');
    SetVal(m, '.cltreferente', '');
    SetVal(m, '.cltemail', '');
    SetVal(m, '.clttel', '');
    SetVal(m, '.cltindirizzo', '');
    SetVal(m, '.cltnote', '');
    m.querySelector('.btnSaveCliente').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditCliente(row)
{
  OpenModalNew('modalCliente', 'Modifica Cliente', function(m) {
    SetVal(m, '.clienteid', row.dataset.id);
    SetVal(m, '.cltnome', row.dataset.nome);
    SetVal(m, '.clttipo', row.dataset.tipo);
    SetVal(m, '.cltpiva', row.dataset.piva);
    SetVal(m, '.cltcf', row.dataset.cf);
    SetVal(m, '.cltreferente', row.dataset.referente);
    SetVal(m, '.cltemail', row.dataset.email);
    SetVal(m, '.clttel', row.dataset.telefono);
    SetVal(m, '.cltindirizzo', row.dataset.indirizzo);
    SetVal(m, '.cltnote', row.dataset.note);
    CheckClienteForm();
  });
};
function OpenNewFornitore()
{
  OpenModalNew('modalFornitore', 'Nuovo Fornitore', function(m) {
    SetVal(m, '.fornitoreid', '');
    SetVal(m, '.fornnome', '');
    SetVal(m, '.forncategoria', '');
    SetVal(m, '.fornpiva', '');
    SetVal(m, '.fornreferente', '');
    SetVal(m, '.fornemail', '');
    SetVal(m, '.forntel', '');
    SetVal(m, '.forniban', '');
    SetVal(m, '.fornindirizzo', '');
    SetVal(m, '.fornnote', '');
    m.querySelector('.btnSaveFornitore').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditFornitore(row)
{
  OpenModalNew('modalFornitore', 'Modifica Fornitore', function(m) {
    SetVal(m, '.fornitoreid', row.dataset.id);
    SetVal(m, '.fornnome', row.dataset.nome);
    SetVal(m, '.forncategoria', row.dataset.categoria);
    SetVal(m, '.fornpiva', row.dataset.piva);
    SetVal(m, '.fornreferente', row.dataset.referente);
    SetVal(m, '.fornemail', row.dataset.email);
    SetVal(m, '.forntel', row.dataset.telefono);
    SetVal(m, '.forniban', row.dataset.iban);
    SetVal(m, '.fornindirizzo', row.dataset.indirizzo);
    SetVal(m, '.fornnote', row.dataset.note);
    CheckFornitoreForm();
  });
};
function OpenNewMezzo()
{
  OpenModalNew('modalMezzo', 'Nuovo Mezzo', function(m) {
    SetVal(m, '.mezzoid', '');
    SetVal(m, '.meznome', '');
    SetVal(m, '.meztipo', '');
    SetVal(m, '.meztarga', '');
    SetVal(m, '.mezseriale', '');
    SetVal(m, '.mezdtrevisione', '');
    SetVal(m, '.mezdtassicurazione', '');
    SetVal(m, '.meznote', '');
    m.querySelector('.btnSaveMezzo').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditMezzo(row)
{
  OpenModalNew('modalMezzo', 'Modifica Mezzo', function(m) {
    SetVal(m, '.mezzoid', row.dataset.id);
    SetVal(m, '.meznome', row.dataset.nome);
    SetVal(m, '.meztipo', row.dataset.tipo);
    SetVal(m, '.meztarga', row.dataset.targa);
    SetVal(m, '.mezseriale', row.dataset.seriale);
    SetVal(m, '.mezdtrevisione', row.dataset.dtRevisione);
    SetVal(m, '.mezdtassicurazione', row.dataset.dtAssicurazione);
    SetVal(m, '.meznote', row.dataset.note);
    CheckMezzoForm();
  });
};
function OpenNewMateriale()
{
  OpenModalNew('modalMateriale', 'Nuovo Ordine Materiale', function(m) {
    SetVal(m, '.materialeid', '');
    SetVal(m, '.matcantiere', '');
    SetVal(m, '.matfornitore', '');
    SetVal(m, '.matcategoria', '');
    SetVal(m, '.matdesc', '');
    SetVal(m, '.matqta', '');
    SetVal(m, '.matum', '');
    SetVal(m, '.matprezzo', '');
    SetVal(m, '.matstato', 'ordinato');
    SetVal(m, '.matdtordine', '');
    SetVal(m, '.matdtconsegna', '');
    SetVal(m, '.matnote', '');
    m.querySelector('.btnSaveMateriale').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditMateriale(row)
{
  OpenModalNew('modalMateriale', 'Modifica Materiale', function(m) {
    SetVal(m, '.materialeid', row.dataset.id);
    SetVal(m, '.matcantiere', row.dataset.idCantiere);
    SetVal(m, '.matfornitore', row.dataset.idFornitore);
    SetVal(m, '.matcategoria', row.dataset.idCategoria);
    SetVal(m, '.matdesc', row.dataset.desc);
    SetVal(m, '.matqta', row.dataset.qta);
    SetVal(m, '.matum', row.dataset.um);
    SetVal(m, '.matprezzo', row.dataset.prezzo);
    SetVal(m, '.matstato', row.dataset.stato);
    SetVal(m, '.matdtordine', row.dataset.dtOrdine);
    SetVal(m, '.matdtconsegna', row.dataset.dtConsegna);
    SetVal(m, '.matnote', row.dataset.note);
    CheckMaterialeForm();
  });
};
function OpenNewDocumento()
{
  OpenModalNew('modalDocumento', 'Carica Documento', function(m) {
    SetVal(m, '.doctipo', '');
    SetVal(m, '.doccantiere', '');
    SetVal(m, '.docnome', '');
    SetVal(m, '.docdesc', '');
    SetVal(m, '.docemissione', '');
    SetVal(m, '.docscadenza', '');
    var fileInput = m.querySelector('.docfile');
    if (fileInput) { fileInput.value = ''; }
    m.querySelector('.btnSaveDocumento').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenNewAttivita()
{
  OpenModalNew('modalAttivita', 'Nuova Attività', function(m) {
    SetVal(m, '.attivitaid', '');
    SetVal(m, '.attnome', '');
    SetVal(m, '.attpadre', '');
    SetVal(m, '.attdtinizioprev', '');
    SetVal(m, '.attdtfineprev', '');
    SetVal(m, '.attpct', '0');
    SetVal(m, '.attbudget', '0');
    SetVal(m, '.attcosteff', '0');
    SetVal(m, '.attdtinizioeff', '');
    SetVal(m, '.attdtfineeff', '');
    SetVal(m, '.attordine', '0');
    m.querySelector('.btnSaveAttivita').disabled = true;
    var hint = m.querySelector('.msghint'); if (hint) { hint.classList.add('d-none'); }
  });
};
function OpenEditAttivita(row)
{
  OpenModalNew('modalAttivita', 'Modifica Attività', function(m) {
    SetVal(m, '.attivitaid', row.dataset.id);
    SetVal(m, '.attnome', row.dataset.nome);
    SetVal(m, '.attpadre', row.dataset.idPadre);
    SetVal(m, '.attdtinizioprev', row.dataset.dtInizioPrev);
    SetVal(m, '.attdtfineprev', row.dataset.dtFinePrev);
    SetVal(m, '.attpct', row.dataset.pct);
    SetVal(m, '.attbudget', row.dataset.budget);
    SetVal(m, '.attcosteff', row.dataset.costoEff);
    SetVal(m, '.attordine', row.dataset.ordine);
    SetVal(m, '.attdtinizioeff', '');
    SetVal(m, '.attdtfineeff', '');
    CheckAttivitaForm();
  });
};
function LoadDashboard()
{
  var data = new FormData();
  data.append('compose', 'cantieri_attivi');
  Compose(data);
};
function LoadFoglioGiornaliero()
{
  var idCantiere = GetAppIdItem('id_cantiere');
  if (!idCantiere) { return; }
  var data = new FormData();
  data.append('compose', 'foglio_giornaliero');
  data.append('id_cantiere', idCantiere);
  data.append('data', new Date().toISOString().slice(0, 10));
  Compose(data);
};
// ── FORM VALIDATORS ──────────────────────────────────────────
function CheckLoginForm()
{
  var btn = document.querySelector('.btnLogin');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.loginrequired').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  btn.disabled = !allValid;
};
function CheckCantiereForm()
{
  var btn = document.querySelector('.btnSaveCantiere');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.cantierereq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var dtstart = document.querySelector('.cntdtstart');
  var dtend   = document.querySelector('.cntdtend');
  var dateErr = document.querySelector('.dateerror');
  var dateInvalid = allValid && dtstart && dtend && dtstart.value && dtend.value && dtstart.value > dtend.value;
  if (dateInvalid)
  {
    allValid = false;
    if (dtstart) { dtstart.classList.add('is-invalid'); }
    if (dtend)   { dtend.classList.add('is-invalid'); }
    if (dateErr) { dateErr.classList.remove('d-none'); }
  }
  else
  {
    if (dtstart) { dtstart.classList.remove('is-invalid'); }
    if (dtend)   { dtend.classList.remove('is-invalid'); }
    if (dateErr) { dateErr.classList.add('d-none'); }
  }
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckOperaioForm()
{
  var btn = document.querySelector('.btnSaveOperaio');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.operaioreq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckClienteForm()
{
  var btn = document.querySelector('.btnSaveCliente');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.clientereq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckFornitoreForm()
{
  var btn = document.querySelector('.btnSaveFornitore');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.fornitorereq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckPresenzaForm()
{
  var btn = document.querySelector('.btnSavePresenza');
  if (!btn) { return; }
  var uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  var allValid = true;
  document.querySelectorAll('.presenzareq').forEach(function(field)
  {
    if (field.type === 'hidden')
    {
      if (!uuidRegex.test(field.value)) { allValid = false; }
    }
    else if (field.type === 'date')
    {
      if (field.value === '') { allValid = false; }
    }
    else
    {
      if (field.value.trim() === '') { allValid = false; }
    }
  });
  btn.disabled = !allValid;
};
function CheckMezzoForm()
{
  var btn = document.querySelector('.btnSaveMezzo');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.mezzoreq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckMaterialeForm()
{
  var btn = document.querySelector('.btnSaveMateriale');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.materialereq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckDocumentoForm()
{
  var btn = document.querySelector('.btnSaveDocumento');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.documentoreq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
function CheckAttivitaForm()
{
  var btn = document.querySelector('.btnSaveAttivita');
  if (!btn) { return; }
  var allValid = true;
  document.querySelectorAll('.attivitareq').forEach(function(field)
  {
    if (field.value.trim() === '') { allValid = false; }
  });
  var hint = document.querySelector('.msghint');
  if (hint) { hint.classList.toggle('d-none', allValid); }
  btn.disabled = !allValid;
};
// ── SAVE FUNCTIONS ────────────────────────────────────────────
function Login()
{
  var data = new FormData();
  data.append('action',   'login');
  data.append('username', document.getElementById(GetInputId('loginunm')).value.trim());
  data.append('pwd',      document.getElementById(GetInputId('loginpwd')).value);
  Perform(data);
};
function Logout()
{
  var data = new FormData();
  data.append('action', 'logout');
  Perform(data);
};
function SaveCantiere()
{
  var data = new FormData();
  var idField = document.querySelector('.cantiereid');
  data.append('action',             idField && idField.value ? 'cantiere_update' : 'cantiere_create');
  if (idField && idField.value)     { data.append('id', idField.value); }
  data.append('nome',               document.getElementById(GetInputId('cntnome')).value.trim());
  data.append('id_cliente',         document.getElementById(GetInputId('cntcliente')).value);
  data.append('indirizzo',          document.getElementById(GetInputId('cntindirizzo')).value.trim());
  data.append('data_inizio',        document.getElementById(GetInputId('cntdtstart')).value);
  data.append('data_fine_prevista', document.getElementById(GetInputId('cntdtend')).value);
  data.append('stato',              document.getElementById(GetInputId('cntstato')).value);
  data.append('importo_contratto',  document.getElementById(GetInputId('cntimporto')).value);
  data.append('tipo_lavori',        document.getElementById(GetInputId('cnttipo')).value.trim());
  data.append('note',               document.getElementById(GetInputId('cntnote')).value.trim());
  Perform(data);
};
function SaveOperaio()
{
  var data = new FormData();
  var idField = document.querySelector('.operaioid');
  data.append('action',           idField && idField.value ? 'operaio_update' : 'operaio_create');
  if (idField && idField.value)   { data.append('id', idField.value); }
  data.append('nome',             document.getElementById(GetInputId('opnome')).value.trim());
  data.append('cognome',          document.getElementById(GetInputId('opcognome')).value.trim());
  data.append('codice_fiscale',   document.getElementById(GetInputId('opcf')).value.trim().toUpperCase());
  data.append('telefono',         document.getElementById(GetInputId('optel')).value.trim());
  data.append('email',            document.getElementById(GetInputId('opemail')).value.trim());
  data.append('data_nascita',     document.getElementById(GetInputId('opdtnascita')).value);
  data.append('data_assunzione',  document.getElementById(GetInputId('opdtassunzione')).value);
  Perform(data);
};
function SaveCliente()
{
  var data = new FormData();
  var idField = document.querySelector('.clienteid');
  data.append('action',           idField && idField.value ? 'cliente_update' : 'cliente_create');
  if (idField && idField.value)   { data.append('id', idField.value); }
  data.append('ragione_sociale',  document.getElementById(GetInputId('cltnome')).value.trim());
  data.append('tipo',             document.getElementById(GetInputId('clttipo')).value);
  data.append('piva',             document.getElementById(GetInputId('cltpiva')).value.trim());
  data.append('codice_fiscale',   document.getElementById(GetInputId('cltcf')).value.trim().toUpperCase());
  data.append('referente',        document.getElementById(GetInputId('cltreferente')).value.trim());
  data.append('email',            document.getElementById(GetInputId('cltemail')).value.trim());
  data.append('telefono',         document.getElementById(GetInputId('clttel')).value.trim());
  data.append('indirizzo',        document.getElementById(GetInputId('cltindirizzo')).value.trim());
  data.append('note',             document.getElementById(GetInputId('cltnote')).value.trim());
  Perform(data);
};
function SaveFornitore()
{
  var data = new FormData();
  var idField = document.querySelector('.fornitoreid');
  data.append('action',           idField && idField.value ? 'fornitore_update' : 'fornitore_create');
  if (idField && idField.value)   { data.append('id', idField.value); }
  data.append('ragione_sociale',  document.getElementById(GetInputId('fornnome')).value.trim());
  data.append('categoria',        document.getElementById(GetInputId('forncategoria')).value);
  data.append('piva',             document.getElementById(GetInputId('fornpiva')).value.trim());
  data.append('referente',        document.getElementById(GetInputId('fornreferente')).value.trim());
  data.append('email',            document.getElementById(GetInputId('fornemail')).value.trim());
  data.append('telefono',         document.getElementById(GetInputId('forntel')).value.trim());
  data.append('iban',             document.getElementById(GetInputId('forniban')).value.trim());
  data.append('indirizzo',        document.getElementById(GetInputId('fornindirizzo')).value.trim());
  data.append('note',             document.getElementById(GetInputId('fornnote')).value.trim());
  Perform(data);
};
function SalvaPresenza(idOperaio)
{
  var card = document.querySelector('.workercard[data-id-operaio="' + idOperaio + '"]');
  if (!card) { return; }
  var data = new FormData();
  data.append('action',             'presenza_upsert');
  data.append('id_cantiere',        GetAppIdItem('id_cantiere'));
  data.append('id_operaio',         idOperaio);
  data.append('data',               GetAppIdItem('data_corrente'));
  data.append('stato',              card.dataset.state || 'presente');
  data.append('ore_ordinarie',      card.dataset.oreOrd || '0');
  data.append('ore_straordinarie',  card.dataset.oreStr || '0');
  data.append('note',               (card.querySelector('.presenzanote') || {value: ''}).value);
  Perform(data);
};
function SalvaFoglioGiornaliero()
{
  var cards = document.querySelectorAll('.workercard');
  var presenze = [];
  cards.forEach(function(card)
  {
    presenze.push({
      id_operaio:        card.dataset.idOperaio,
      stato:             card.dataset.state || 'presente',
      ore_ordinarie:     card.dataset.oreOrd || '0',
      ore_straordinarie: card.dataset.oreStr || '0',
      note:              (card.querySelector('.presenzanote') || {value: ''}).value
    });
  });
  var data = new FormData();
  data.append('action',       'foglio_giornaliero_save');
  data.append('id_cantiere',  GetAppIdItem('id_cantiere'));
  data.append('data',         GetAppIdItem('data_corrente'));
  data.append('presenze',     JSON.stringify(presenze));
  Perform(data);
};
function ChiudiSettimana()
{
  var data = new FormData();
  data.append('action',      'settimana_chiudi');
  data.append('id_cantiere', GetAppIdItem('id_cantiere'));
  data.append('anno',        GetAppIdItem('anno_corrente'));
  data.append('settimana',   GetAppIdItem('settimana_corrente'));
  Perform(data);
};
function SaveMezzo()
{
  var data = new FormData();
  var idField = document.querySelector('.mezzoid');
  data.append('action',                        idField && idField.value ? 'mezzo_update' : 'mezzo_create');
  if (idField && idField.value)                { data.append('id', idField.value); }
  data.append('nome',                          document.getElementById(GetInputId('meznome')).value.trim());
  data.append('tipo',                          document.getElementById(GetInputId('meztipo')).value);
  data.append('targa',                         document.getElementById(GetInputId('meztarga')).value.trim());
  data.append('numero_seriale',                document.getElementById(GetInputId('mezseriale')).value.trim());
  data.append('data_revisione',                document.getElementById(GetInputId('mezdtrevisione')).value);
  data.append('data_scadenza_assicurazione',   document.getElementById(GetInputId('mezdtassicurazione')).value);
  data.append('note',                          document.getElementById(GetInputId('meznote')).value.trim());
  Perform(data);
};
function SaveMateriale()
{
  var data = new FormData();
  var idField = document.querySelector('.materialeid');
  data.append('action',                    idField && idField.value ? 'materiale_update' : 'materiale_create');
  if (idField && idField.value)            { data.append('id', idField.value); }
  data.append('id_cantiere',               document.getElementById(GetInputId('matcantiere')).value);
  data.append('id_fornitore',              document.getElementById(GetInputId('matfornitore')).value);
  data.append('id_categoria',              document.getElementById(GetInputId('matcategoria')).value);
  data.append('descrizione',              document.getElementById(GetInputId('matdesc')).value.trim());
  data.append('quantita',                 document.getElementById(GetInputId('matqta')).value);
  data.append('unita_misura',             document.getElementById(GetInputId('matum')).value.trim());
  data.append('costo_unitario',           document.getElementById(GetInputId('matprezzo')).value);
  data.append('stato',                    document.getElementById(GetInputId('matstato')).value);
  data.append('data_ordine',              document.getElementById(GetInputId('matdtordine')).value);
  data.append('data_consegna_prevista',   document.getElementById(GetInputId('matdtconsegna')).value);
  data.append('note',                     document.getElementById(GetInputId('matnote')).value.trim());
  Perform(data);
};
function SaveDocumento()
{
  var data = new FormData();
  data.append('action',         'documento_create');
  data.append('id_tipo',        document.getElementById(GetInputId('doctipo')).value);
  data.append('id_cantiere',    document.getElementById(GetInputId('doccantiere')).value);
  data.append('nome',           document.getElementById(GetInputId('docnome')).value.trim());
  data.append('descrizione',    document.getElementById(GetInputId('docdesc')).value.trim());
  data.append('data_emissione', document.getElementById(GetInputId('docemissione')).value);
  data.append('data_scadenza',  document.getElementById(GetInputId('docscadenza')).value);
  var fileInput = document.querySelector('.docfile');
  if (fileInput && fileInput.files[0]) { data.append('file', fileInput.files[0]); }
  Perform(data);
};
function SaveAttivita()
{
  var data = new FormData();
  var idField = document.querySelector('.attivitaid');
  data.append('action',                       'attivita_gantt_upsert');
  if (idField && idField.value)               { data.append('id', idField.value); }
  data.append('id_cantiere',                  GetAppIdItem('id_cantiere') || '');
  data.append('nome',                         document.getElementById(GetInputId('attnome')).value.trim());
  data.append('id_padre',                     document.getElementById(GetInputId('attpadre')).value);
  data.append('data_inizio_prevista',         document.getElementById(GetInputId('attdtinizioprev')).value);
  data.append('data_fine_prevista',           document.getElementById(GetInputId('attdtfineprev')).value);
  data.append('percentuale_completamento',    document.getElementById(GetInputId('attpct')).value);
  data.append('budget_previsto',              document.getElementById(GetInputId('attbudget')).value);
  data.append('costo_effettivo',              document.getElementById(GetInputId('attcosteff')).value);
  data.append('data_inizio_effettiva',        document.getElementById(GetInputId('attdtinizioeff')).value);
  data.append('data_fine_effettiva',          document.getElementById(GetInputId('attdtfineeff')).value);
  data.append('ordine',                       document.getElementById(GetInputId('attordine')).value);
  Perform(data);
};
function UpdateDailyProgress()
{
  var cards = document.querySelectorAll('.workercard');
  var total = cards.length;
  if (total === 0) { return; }
  var done = 0;
  cards.forEach(function(card)
  {
    if (card.dataset.state && card.dataset.state !== '') { done++; }
  });
  var pct = Math.round((done / total) * 100);
  var bar = document.querySelector('.progressbar');
  if (bar)
  {
    bar.style.width = pct + '%';
    bar.setAttribute('aria-valuenow', pct);
    bar.textContent = pct + '%';
  }
  var counter = document.querySelector('.progresscounter');
  if (counter) { counter.textContent = done + '/' + total; }
};
// ── UTILITIES ─────────────────────────────────────────────────
function MaxIdRow(classname)
{
  var idRow = 0;
  var rows = document.querySelectorAll('.' + classname);
  rows.forEach(function(row)
  {
    var rowId = parseInt(row.dataset.idrow) || 0;
    if (rowId > idRow) { idRow = rowId + 1; }
    else               { idRow++; }
  });
  return idRow;
};
function WhitheSpaceOnly(str)
{
  if (str === null || str === '') { return true; }
  var mystring = str.replace(/^\s+|\s+$/g, '');
  return mystring.length === 0;
};
function SearchTextInRow(searchtext)
{
  var st = searchtext.toLowerCase();
  document.querySelectorAll('.listrow').forEach(function(listrow)
  {
    var txt = '';
    listrow.querySelectorAll('.textrow').forEach(function(cell) { txt += cell.textContent.toLowerCase(); });
    listrow.classList.toggle('d-none', txt.indexOf(st) < 0);
  });
};
function CloseAllSelectDropdowns()
{
  document.querySelectorAll('.selectdropdown').forEach(function(dd) { dd.classList.add('d-none'); });
};
function FilterSelectDropdown(input)
{
  var searchText = input.value.toLowerCase();
  var dropdown = input.closest('.customselect').querySelector('.selectdropdown');
  dropdown.classList.remove('d-none');
  dropdown.querySelectorAll('li').forEach(function(item)
  {
    if (item.dataset.value === '') { return; }
    item.hidden = item.textContent.toLowerCase().indexOf(searchText) < 0;
  });
};
// ── EVENT DELEGATION — CLICK ──────────────────────────────────
document.addEventListener('click', function(event)
{
  // login / logout
  if (event.target.id === 'btnlogin' || event.target.closest('#btnlogin'))
  {
    Login(); return;
  }
  if (event.target.id === 'btnlogout' || event.target.closest('#btnlogout'))
  {
    Logout(); return;
  }
  // ── New buttons ──
  if (event.target.classList.contains('btnNewCantiere') || event.target.closest('.btnNewCantiere'))
  {
    OpenNewCantiere(); return;
  }
  if (event.target.classList.contains('btnNewOperaio') || event.target.closest('.btnNewOperaio'))
  {
    OpenNewOperaio(); return;
  }
  if (event.target.classList.contains('btnNewCliente') || event.target.closest('.btnNewCliente'))
  {
    OpenNewCliente(); return;
  }
  if (event.target.classList.contains('btnNewFornitore') || event.target.closest('.btnNewFornitore'))
  {
    OpenNewFornitore(); return;
  }
  if (event.target.classList.contains('btnNewMezzo') || event.target.closest('.btnNewMezzo'))
  {
    OpenNewMezzo(); return;
  }
  if (event.target.classList.contains('btnNewMateriale') || event.target.closest('.btnNewMateriale'))
  {
    OpenNewMateriale(); return;
  }
  if (event.target.classList.contains('btnNewDocumento') || event.target.closest('.btnNewDocumento'))
  {
    OpenNewDocumento(); return;
  }
  if (event.target.classList.contains('btnNewAttivita') || event.target.closest('.btnNewAttivita'))
  {
    OpenNewAttivita(); return;
  }
  // ── Edit buttons ──
  var editCantiereBtn = event.target.closest('.btnEditCantiere');
  if (editCantiereBtn)
  {
    var row = editCantiereBtn.closest('.listrow');
    if (row) { OpenEditCantiere(row); }
    return;
  }
  var editOperaioBtn = event.target.closest('.btnEditOperaio');
  if (editOperaioBtn)
  {
    var row = editOperaioBtn.closest('.listrow');
    if (row) { OpenEditOperaio(row); }
    return;
  }
  var editClienteBtn = event.target.closest('.btnEditCliente');
  if (editClienteBtn)
  {
    var row = editClienteBtn.closest('.listrow');
    if (row) { OpenEditCliente(row); }
    return;
  }
  var editFornitoreBtn = event.target.closest('.btnEditFornitore');
  if (editFornitoreBtn)
  {
    var row = editFornitoreBtn.closest('.listrow');
    if (row) { OpenEditFornitore(row); }
    return;
  }
  var editMezzoBtn = event.target.closest('.btnEditMezzo');
  if (editMezzoBtn)
  {
    var row = editMezzoBtn.closest('.listrow');
    if (row) { OpenEditMezzo(row); }
    return;
  }
  var editMaterialeBtn = event.target.closest('.btnEditMateriale');
  if (editMaterialeBtn)
  {
    var row = editMaterialeBtn.closest('.listrow');
    if (row) { OpenEditMateriale(row); }
    return;
  }
  var editAttivitaBtn = event.target.closest('.btnEditAttivita');
  if (editAttivitaBtn)
  {
    var row = editAttivitaBtn.closest('.listrow');
    if (row) { OpenEditAttivita(row); }
    return;
  }
  // ── Save buttons ──
  if (event.target.classList.contains('btnSaveCantiere'))  { SaveCantiere();  return; }
  if (event.target.classList.contains('btnSaveOperaio'))   { SaveOperaio();   return; }
  if (event.target.classList.contains('btnSaveCliente'))   { SaveCliente();   return; }
  if (event.target.classList.contains('btnSaveFornitore')) { SaveFornitore(); return; }
  if (event.target.classList.contains('btnSaveMezzo'))     { SaveMezzo();     return; }
  if (event.target.classList.contains('btnSaveMateriale')) { SaveMateriale(); return; }
  if (event.target.classList.contains('btnSaveDocumento')) { SaveDocumento(); return; }
  if (event.target.classList.contains('btnSaveAttivita'))  { SaveAttivita();  return; }
  // ── Presenze ──
  if (event.target.classList.contains('btnSalvaFoglio'))
  {
    SalvaFoglioGiornaliero(); return;
  }
  if (event.target.classList.contains('btnChiudiSettimana'))
  {
    ChiudiSettimana(); return;
  }
  var presBtn = event.target.closest('.btnSalvaPresenza');
  if (presBtn)
  {
    var presCard = presBtn.closest('.workercard');
    if (presCard) { SalvaPresenza(presCard.dataset.idOperaio); }
    return;
  }
  // ── Operaio toggle ──
  var toggleBtn = event.target.closest('.btnToggleOperaio');
  if (toggleBtn)
  {
    var li = toggleBtn.closest('.listrow');
    if (li && li.dataset.id)
    {
      var toggleData = new FormData();
      toggleData.append('action', 'operaio_toggle');
      toggleData.append('id', li.dataset.id);
      Perform(toggleData);
    }
    return;
  }
  // ── Custom select dropdown ──
  var srcInput = event.target.closest('.customselect');
  if (srcInput && event.target.tagName === 'INPUT' && event.target.type === 'text')
  {
    CloseAllSelectDropdowns();
    srcInput.querySelector('.selectdropdown').classList.remove('d-none');
    return;
  }
  var listItem = event.target.closest('.selectdropdown li');
  if (listItem)
  {
    var customSelect = listItem.closest('.customselect');
    var srcClass     = customSelect.dataset.src;
    var targetClass  = customSelect.dataset.target;
    document.querySelector('.' + srcClass).value = listItem.textContent.trim();
    document.getElementById(GetInputId(targetClass)).value = listItem.dataset.value;
    customSelect.querySelector('.selectdropdown').classList.add('d-none');
    CheckCantiereForm();
    CheckMaterialeForm();
    CheckDocumentoForm();
    CheckPresenzaForm();
    return;
  }
  if (!event.target.closest('.customselect')) { CloseAllSelectDropdowns(); }
  // ── Prezziario DEI ──
  if (event.target.classList.contains('btnImportaDei'))
  {
    var m = new bootstrap.Modal(document.getElementById('modalImportaDei'));
    m.show();
    return;
  }
  if (event.target.classList.contains('btnAvviaImportDei'))
  {
    ImportaDei(); return;
  }
  // ── Computi ──
  if (event.target.classList.contains('btnImportaComputo'))
  {
    var m = new bootstrap.Modal(document.getElementById('modalImportaComputo'));
    m.show();
    return;
  }
  if (event.target.classList.contains('btnAvviaImportComputo'))
  {
    ImportaComputo(); return;
  }
  var analisiBtn = event.target.closest('.btnAnalisiComputo');
  if (analisiBtn)
  {
    var idComputo = analisiBtn.dataset.id;
    SetAppIdItem('id_computo_analisi', idComputo);
    var d = new FormData();
    d.append('page', 'analisi_computo');
    d.append('id_computo', idComputo);
    Routing(d);
    return;
  }
  var elimBtn = event.target.closest('.btnEliminaComputo');
  if (elimBtn)
  {
    if (!confirm('Eliminare questo computo e tutte le sue voci?')) return;
    var d = new FormData();
    d.append('action', 'computo_elimina');
    d.append('id', elimBtn.dataset.id);
    Perform(d);
    return;
  }
  if (event.target.classList.contains('btnTornaComputi'))
  {
    var d = new FormData();
    d.append('page', 'computi');
    var saved = GetAppIdItem('id_cantiere_computi');
    if (saved) d.append('id_cantiere', saved);
    Routing(d);
    return;
  }
  // ── Navigation via data-href ──
  if (event.target.closest('.ishref'))
  {
    window.location = event.target.closest('.ishref').dataset.href;
    return;
  }
});
// ── EVENT DELEGATION — INPUT ──────────────────────────────────
document.addEventListener('input', function(event)
{
  if (event.target.classList.contains('txtsearch'))
  {
    SearchTextInRow(event.target.value);
  }
  if (event.target.closest('.customselect') && event.target.type === 'text')
  {
    FilterSelectDropdown(event.target);
  }
  if (event.target.classList.contains('loginrequired')) { CheckLoginForm(); }
  if (event.target.classList.contains('cantierereq'))   { CheckCantiereForm(); }
  if (event.target.classList.contains('operaioreq'))    { CheckOperaioForm(); }
  if (event.target.classList.contains('clientereq'))    { CheckClienteForm(); }
  if (event.target.classList.contains('fornitorereq'))  { CheckFornitoreForm(); }
  if (event.target.classList.contains('presenzareq'))   { CheckPresenzaForm(); }
  if (event.target.classList.contains('mezzoreq'))      { CheckMezzoForm(); }
  if (event.target.classList.contains('materialereq'))  { CheckMaterialeForm(); }
  if (event.target.classList.contains('documentoreq'))  { CheckDocumentoForm(); }
  if (event.target.classList.contains('attivitareq'))   { CheckAttivitaForm(); }
});
// ── EVENT DELEGATION — CHANGE (selects trigger change not input) ──
document.addEventListener('change', function(event)
{
  if (event.target.classList.contains('cantierereq'))  { CheckCantiereForm(); }
  if (event.target.classList.contains('operaioreq'))   { CheckOperaioForm(); }
  if (event.target.classList.contains('clientereq'))   { CheckClienteForm(); }
  if (event.target.classList.contains('fornitorereq')) { CheckFornitoreForm(); }
  if (event.target.classList.contains('mezzoreq'))     { CheckMezzoForm(); }
  if (event.target.classList.contains('materialereq')) { CheckMaterialeForm(); }
  if (event.target.classList.contains('documentoreq')) { CheckDocumentoForm(); }
  if (event.target.classList.contains('attivitareq'))  { CheckAttivitaForm(); }
  // DEI file input → abilita bottone
  if (event.target.classList.contains('deiFile'))
  {
    document.querySelector('.btnAvviaImportDei').disabled = !event.target.files.length;
  }
  // Computo file input → abilita bottone se anche cantiere selezionato
  if (event.target.classList.contains('computoFile')) { CheckComputoImportForm(); }
  if (event.target.classList.contains('computoCantiere')) { CheckComputoImportForm(); }
  // Ricerca rapida tabella DEI
  if (event.target.classList.contains('deiSearch'))
  {
    var q = event.target.value.toLowerCase();
    document.querySelectorAll('#tableDei tbody tr').forEach(function(tr)
    {
      tr.style.display = tr.textContent.toLowerCase().includes(q) ? '' : 'none';
    });
  }
  // Cambio cantiere nella pagina computi
  if (event.target.classList.contains('selCantiereComputi'))
  {
    var idCant = event.target.value;
    var d = new FormData();
    d.append('page', 'computi');
    d.append('id_cantiere', idCant);
    if (idCant) { SetAppIdItem('id_cantiere_computi', idCant); }
    Routing(d);
  }
});

// ══════════════════════════════════════════════════════════════
// COMPUTI METRICI — PDF.js extraction + import
// ══════════════════════════════════════════════════════════════

// Configura worker PDF.js (CDN)
if (typeof pdfjsLib !== 'undefined') {
  pdfjsLib.GlobalWorkerOptions.workerSrc =
    'https://cdnjs.cloudflare.com/ajax/libs/pdf.js/3.11.174/pdf.worker.min.js';
}

async function ExtractPdfText(file, onProgress) {
  if (typeof pdfjsLib === 'undefined') {
    throw new Error('PDF.js non disponibile. Verifica la connessione internet.');
  }
  var arrayBuffer = await file.arrayBuffer();
  var pdf = await pdfjsLib.getDocument({ data: arrayBuffer }).promise;
  var testo = '';
  for (var i = 1; i <= pdf.numPages; i++) {
    var page    = await pdf.getPage(i);
    var content = await page.getTextContent();
    testo += content.items.map(function(item) { return item.str; }).join(' ') + '\n';
    if (onProgress) { onProgress(i, pdf.numPages); }
  }
  return testo;
}

function CheckComputoImportForm() {
  var btn  = document.querySelector('.btnAvviaImportComputo');
  var file = document.querySelector('.computoFile');
  var cant = document.querySelector('.computoCantiere');
  if (btn && file && cant) {
    btn.disabled = !(file.files.length && cant.value);
  }
}

async function ImportaDei() {
  var fileInput  = document.querySelector('.deiFile');
  var chkSost    = document.querySelector('.deiSostituisci');
  var progressEl = document.querySelector('.deiProgress');
  var labelEl    = document.querySelector('.deiProgressLabel');
  var barEl      = document.querySelector('.deiProgressBar');
  var btn        = document.querySelector('.btnAvviaImportDei');

  if (!fileInput || !fileInput.files[0]) return;
  btn.disabled = true;
  progressEl.classList.remove('d-none');

  try {
    labelEl.textContent = 'Estrazione testo in corso…';
    var testo = await ExtractPdfText(fileInput.files[0], function(pg, tot) {
      var pct = Math.round((pg / tot) * 80);
      barEl.style.width = pct + '%';
      labelEl.textContent = 'Pagina ' + pg + ' di ' + tot + '…';
    });

    barEl.style.width = '90%';
    labelEl.textContent = 'Invio al server…';

    var data = new FormData();
    data.append('action',      'dei_import');
    data.append('testo_pdf',   testo);
    data.append('sostituisci', chkSost && chkSost.checked ? '1' : '0');
    await Perform(data);

    barEl.style.width = '100%';
  } catch (e) {
    alert('Errore: ' + e.message);
    btn.disabled = false;
    progressEl.classList.add('d-none');
  }
}

async function ImportaComputo() {
  var fileInput  = document.querySelector('.computoFile');
  var cantSel    = document.querySelector('.computoCantiere');
  var progressEl = document.querySelector('.computoProgress');
  var labelEl    = document.querySelector('.computoProgressLabel');
  var barEl      = document.querySelector('.computoProgressBar');
  var btn        = document.querySelector('.btnAvviaImportComputo');

  if (!fileInput || !fileInput.files[0] || !cantSel || !cantSel.value) return;
  btn.disabled = true;
  progressEl.classList.remove('d-none');

  try {
    labelEl.textContent = 'Estrazione testo in corso…';
    var testo = await ExtractPdfText(fileInput.files[0], function(pg, tot) {
      var pct = Math.round((pg / tot) * 80);
      barEl.style.width = pct + '%';
      labelEl.textContent = 'Pagina ' + pg + ' di ' + tot + '…';
    });

    barEl.style.width = '90%';
    labelEl.textContent = 'Analisi e salvataggio…';

    var data = new FormData();
    data.append('action',      'computo_import');
    data.append('id_cantiere', cantSel.value);
    data.append('nome_file',   fileInput.files[0].name);
    data.append('testo_pdf',   testo);
    await Perform(data);

    barEl.style.width = '100%';
  } catch (e) {
    alert('Errore: ' + e.message);
    btn.disabled = false;
    progressEl.classList.add('d-none');
  }
}
