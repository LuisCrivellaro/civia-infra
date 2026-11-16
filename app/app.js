// Consulta /health.txt no mesmo servidor e mostra codigo HTTP e tempo de resposta.
// Serve para ver no navegador, durante o teste de falha, quando o site cai e quando volta.
(function () {
  var elHttp = document.getElementById('st-http');
  var elTempo = document.getElementById('st-tempo');
  var elHora = document.getElementById('st-hora');

  function verificar() {
    var inicio = performance.now();
    elHttp.textContent = 'verificando...';
    elHttp.className = '';
    fetch('health.txt?t=' + Date.now(), { cache: 'no-store' })
      .then(function (r) {
        var ms = Math.round(performance.now() - inicio);
        elHttp.textContent = 'HTTP ' + r.status + (r.ok ? ' (no ar)' : ' (erro)');
        elHttp.className = r.ok ? 'ok' : 'erro';
        elTempo.textContent = ms + ' ms';
      })
      .catch(function () {
        elHttp.textContent = 'sem resposta (servidor fora do ar)';
        elHttp.className = 'erro';
        elTempo.textContent = '-';
      })
      .then(function () {
        elHora.textContent = new Date().toLocaleTimeString('pt-BR');
      });
  }

  document.getElementById('btn-verificar').addEventListener('click', verificar);
  verificar();
  setInterval(verificar, 5000);
})();
