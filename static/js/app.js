(() => {
  'use strict';

  const select = document.getElementById('musico-select');
  const name = document.getElementById('artist-name');
  const avatar = document.getElementById('artist-avatar');
  const hint = document.getElementById('artist-hint');
  const band = document.getElementById('artist-band');
  const instrument = document.getElementById('artist-instrument');
  const state = document.getElementById('query-state');
  const help = document.getElementById('panel-help');
  let activeRequest = null;

  function reset() {
    name.textContent = 'Sin seleccionar';
    avatar.textContent = '♪';
    hint.textContent = 'Elegí un nombre para explorar';
    band.textContent = '—';
    instrument.textContent = '—';
    state.textContent = 'LISTO PARA EXPLORAR';
    help.textContent = 'La información se recupera en tiempo real desde la base de datos mediante Flask.';
  }

  select.addEventListener('change', async () => {
    if (activeRequest) activeRequest.abort();
    const id = select.value;
    if (!id) { reset(); return; }

    activeRequest = new AbortController();
    const artistName = select.options[select.selectedIndex].text;
    name.textContent = artistName;
    avatar.textContent = artistName.split(' ').filter(Boolean).slice(0, 2).map(part => part[0].toUpperCase()).join('');
    hint.textContent = 'Consultando el archivo musical';
    band.textContent = '…';
    instrument.textContent = '…';
    state.textContent = 'CONSULTANDO...';
    help.textContent = 'Recuperando los datos del artista.';

    try {
      const response = await fetch(`${select.dataset.apiBase}${encodeURIComponent(id)}`, {
        signal: activeRequest.signal,
        headers: { 'Accept': 'application/json' },
      });
      if (!response.ok) throw new Error('No se pudo recuperar la información.');
      const data = await response.json();
      band.textContent = data.banda;
      instrument.textContent = data.instrumento;
      hint.textContent = 'Perfil disponible en el archivo';
      state.textContent = 'CONSULTA COMPLETA';
      help.textContent = 'Datos obtenidos mediante la función almacenada obtener_musico() de PostgreSQL.';
    } catch (error) {
      if (error.name === 'AbortError') return;
      hint.textContent = 'Consulta no disponible';
      band.textContent = '—';
      instrument.textContent = '—';
      state.textContent = 'ERROR DE CONEXIÓN';
      help.textContent = 'No se pudo consultar el artista. Comprobá la conexión con la base de datos.';
    }
  });
})();
