// Observe T3's existing shell traffic. No requests, credentials, or thread content
// are sent to native code; only a working boolean and a Done count cross the bridge.
(() => {
  if (window.top !== window || !(location.origin === 'https://app.t3.codes' || location.hostname === '127.0.0.1')) return;
  const snapshots = new Map();
  const sockets = new Set();
  let previous;
  // Servers without visited tracking omit lastVisitedAt; T3 then uses its local
  // watermark, keyed by `${environmentId}:${threadId}`.
  const localVisits = () => {
    try { return JSON.parse(window.localStorage.getItem('t3code:ui-state:v1'))?.threadLastVisitedAtById ?? {}; }
    catch { return {}; }
  };
  const isDone = (thread, id, local) => {
    if (!thread.settled || !Number.isFinite(thread.completedAt)) return false;
    const visited = thread.visitedAt === undefined ?
      Object.entries(local).find(([key]) => key.endsWith(`:${id}`))?.[1] : thread.visitedAt;
    // As in T3's sidebar, a never-visited thread counts as read.
    if (!visited) return false;
    const at = Date.parse(visited);
    return Number.isNaN(at) || thread.completedAt > at;
  };
  const publish = () => {
    const live = Array.from(sockets).filter(socket => socket.subscriptions.size > 0);
    const working = live.some(socket => Array.from(socket.state.threads.values()).some(thread => thread.working));
    const local = localVisits();
    const done = new Set();
    for (const socket of live) {
      for (const [id, thread] of socket.state.threads) if (isDone(thread, id, local)) done.add(`${socket.key} ${id}`);
    }
    // Without a live shell the count is unknown, not zero; native keeps the last one.
    const message = live.length > 0 ? {op: 'activity', working, done: done.size} : {op: 'activity', working};
    const next = JSON.stringify(message);
    if (next !== previous) {
      previous = next;
      window.webkit.messageHandlers.t3HudNotifications.postMessage(message);
    }
  };
  const date = value => typeof value === 'string' ? Date.parse(value) : NaN;
  // Stable T3 sends `session`/`latestTurn` shells; nightly sends `status`/`latestRun*` shells.
  const summarize = thread => {
    const hidden = Boolean(thread.archivedAt || thread.deletedAt);
    if ('status' in thread) {
      const pending = thread.pendingRuntimeRequest != null;
      const status = thread.activityRunStatus ?? thread.status;
      const active = ['preparing', 'queued', 'starting', 'running', 'waiting'].includes(status);
      const held = thread.status !== 'failed' && (thread.pendingBackgroundTasks?.length ?? 0) > 0;
      const completedAt = thread.latestRunId == null ? NaN : thread.latestRunCompletedAt === undefined ?
        (['idle', 'completed', 'interrupted', 'failed', 'cancelled', 'rolled_back'].includes(thread.status) ? date(thread.updatedAt) : NaN) :
        date(thread.latestRunCompletedAt);
      return {working: !hidden && !pending && active, completedAt, visitedAt: thread.lastVisitedAt,
        settled: !hidden && !pending && !active && !held && status !== 'idle' && thread.status !== 'failed'};
    }
    const pending = thread.hasPendingApprovals || thread.hasPendingUserInput;
    const failed = thread.session?.status === 'error';
    const active = ['starting', 'running'].includes(thread.session?.status) ||
      (!failed && thread.backgroundLiveness === 'working');
    return {working: !hidden && !pending && active, completedAt: date(thread.latestTurn?.completedAt),
      visitedAt: thread.lastVisitedAt,
      settled: !hidden && !pending && !active && !failed && thread.backgroundLiveness !== 'monitoring'};
  };
  const blank = () => ({sequence: -1, threads: new Map()});
  const snapshot = (state, value) => {
    if (!value || !Number.isSafeInteger(value.snapshotSequence) || !Array.isArray(value.threads) ||
        value.snapshotSequence < state.sequence) return;
    const threads = new Map();
    for (const thread of value.threads) {
      if (thread && typeof thread.id === 'string') threads.set(thread.id, summarize(thread));
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
                  if (['thread-upserted', 'thread.updated'].includes(item.kind) && typeof item.thread?.id === 'string') {
                    socket.state.threads.set(item.thread.id, summarize(item.thread));
                  } else if (['thread-removed', 'thread.removed'].includes(item.kind)) socket.state.threads.delete(item.threadId);
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
  try {
    // T3 rewrites its local visited watermarks through setItem. Patch the prototype:
    // assigning to a Storage instance would store an item instead.
    const prototype = Object.getPrototypeOf(window.localStorage), nativeSetItem = prototype.setItem;
    prototype.setItem = function(...args) {
      const result = Reflect.apply(nativeSetItem, this, args);
      try { if (args[0] === 't3code:ui-state:v1') publish(); } catch {}
      return result;
    };
  } catch {}
  publish();
})();
