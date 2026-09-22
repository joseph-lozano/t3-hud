// Observe T3's existing shell traffic. No requests, credentials, or thread content
// are sent to native code; only an aggregate working boolean crosses the bridge.
(() => {
  if (window.top !== window || !(location.origin === 'https://app.t3.codes' || location.hostname === '127.0.0.1')) return;
  const snapshots = new Map();
  const sockets = new Set();
  let previous;
  const publish = () => {
    const working = Array.from(sockets).some(socket => socket.subscriptions.size > 0 &&
      Array.from(socket.state.threads.values()).some(Boolean));
    if (working !== previous) {
      previous = working;
      window.webkit.messageHandlers.t3HudNotifications.postMessage({op: 'activity', working});
    }
  };
  const isWorking = thread => !thread.archivedAt && !thread.hasPendingApprovals && !thread.hasPendingUserInput &&
    (['starting', 'running'].includes(thread.session?.status) ||
     (thread.session?.status !== 'error' && thread.backgroundLiveness === 'working'));
  const blank = () => ({sequence: -1, threads: new Map()});
  const snapshot = (state, value) => {
    if (!value || !Number.isSafeInteger(value.snapshotSequence) || !Array.isArray(value.threads) ||
        value.snapshotSequence < state.sequence) return;
    const threads = new Map();
    for (const thread of value.threads) {
      if (thread && typeof thread.id === 'string') threads.set(thread.id, isWorking(thread));
    }
    state.sequence = value.snapshotSequence;
    state.threads = threads;
  };
  const key = address => {
    const url = new URL(address, location.href);
    // HTTP shell and WebSocket URLs use the same environment origin. Do not
    // retain query strings: WebSocket URLs can contain one-time credentials.
    return url.host;
  };
  const decode = value => {
    if (value instanceof ArrayBuffer) value = new TextDecoder().decode(value);
    if (typeof value !== 'string' || value.length > 16 * 1024 * 1024) return [];
    try { const parsed = JSON.parse(value); return Array.isArray(parsed) ? parsed : [parsed]; }
    catch { return []; }
  };
  const nativeFetch = window.fetch;
  window.fetch = function(...args) {
    const result = Reflect.apply(nativeFetch, this, args);
    try {
      const url = new URL(typeof args[0] === 'string' || args[0] instanceof URL ? args[0] : args[0].url, location.href);
      if (url.pathname === '/api/orchestration/shell') {
        const origin = key(url);
        result.then(response => {
          if (!response.ok) return;
          return response.clone().json().then(value => {
            const state = snapshots.get(origin) ?? blank();
            snapshot(state, value);
            snapshots.set(origin, state);
            for (const socket of sockets) if (socket.key === origin) snapshot(socket.state, value);
            publish();
          });
        }).catch(() => {});
      }
    } catch {} // Observation must never change T3's request behavior.
    return result;
  };
  const NativeWebSocket = window.WebSocket;
  window.WebSocket = new Proxy(NativeWebSocket, {
    construct(target, args) {
      const ws = Reflect.construct(target, args);
      try {
        const origin = key(ws.url);
        const cached = snapshots.get(origin);
        const socket = {key: origin, subscriptions: new Set(), state: cached ?
          {sequence: cached.sequence, threads: new Map(cached.threads)} : blank()};
        sockets.add(socket);
        const nativeSend = ws.send;
        ws.send = function(data) {
          const result = Reflect.apply(nativeSend, this, [data]);
          try {
            for (const request of decode(data)) {
              if (request?._tag === 'Request' && request.tag === 'orchestration.subscribeShell') {
                socket.subscriptions.add(String(request.id));
                // An HTTP snapshot can arrive after the socket was constructed.
                const latest = snapshots.get(origin);
                if (latest && latest.sequence > socket.state.sequence) {
                  socket.state = {sequence: latest.sequence, threads: new Map(latest.threads)};
                }
              } else if (request?._tag === 'Interrupt') {
                socket.subscriptions.delete(String(request.requestId));
              }
            }
            publish();
          } catch {}
          return result;
        };
        ws.addEventListener('message', event => {
          try {
            for (const message of decode(event.data)) {
              if (!message || !socket.subscriptions.has(String(message.requestId))) continue;
              if (message._tag === 'Exit') { socket.subscriptions.delete(String(message.requestId)); continue; }
              if (message._tag !== 'Chunk' || !Array.isArray(message.values)) continue;
              for (const item of message.values) {
                if (!item) continue;
                if (item.kind === 'snapshot') snapshot(socket.state, item.snapshot);
                else if (Number.isSafeInteger(item.sequence) && item.sequence > socket.state.sequence) {
                  if (item.kind === 'thread-upserted' && typeof item.thread?.id === 'string') {
                    socket.state.threads.set(item.thread.id, isWorking(item.thread));
                  } else if (item.kind === 'thread-removed') socket.state.threads.delete(item.threadId);
                  socket.state.sequence = item.sequence;
                }
              }
              const cached = snapshots.get(origin);
              if (!cached || socket.state.sequence >= cached.sequence) {
                snapshots.set(origin, {sequence: socket.state.sequence, threads: new Map(socket.state.threads)});
              }
            }
            publish();
          } catch {}
        });
        ws.addEventListener('close', () => { sockets.delete(socket); publish(); });
      } catch {}
      return ws;
    }
  });
  publish();
})();
