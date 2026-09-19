// Experimental T3 browser notification adapter. No server client or unread state.
(() => {
  if (window.top !== window || !(location.origin === 'https://app.t3.codes' || location.hostname === '127.0.0.1')) return;
  const send = body => window.webkit.messageHandlers.t3HudNotifications.postMessage(body);
  const entries = new Map();
  const pendingPermission = [];
  let permission = /* HUD_PERMISSION */ 'default';
  let counter = 0;
  class HUDNotification extends EventTarget {
    static get permission() { return permission; }
    static get maxActions() { return 0; }
    static requestPermission(callback) {
      if (permission !== 'default') { callback?.(permission); return Promise.resolve(permission); }
      return new Promise(resolve => { pendingPermission.push(result => { callback?.(result); resolve(result); }); if (pendingPermission.length === 1) send({op:'permission'}); });
    }
    constructor(title, options = {}) {
      super();
      if (permission !== 'granted') throw new DOMException('Enable HUD alerts first', 'NotAllowedError');
      this.title = String(title); this.body = String(options.body ?? ''); this.tag = String(options.tag ?? ''); this.silent = true;
      this.id = `hud-${++counter}`;
      entries.set(this.id, this);
      send({op:'notify',id:this.id,title:this.title,body:this.body,tag:this.tag});
      queueMicrotask(() => this.dispatchEvent(new Event('show')));
    }
    close() { if (entries.delete(this.id)) { send({op:'close',id:this.id}); this.dispatchEvent(new Event('close')); } }
    dispatchEvent(event) { const ok=super.dispatchEvent(event); const handler=this['on'+event.type]; if(typeof handler==='function')handler.call(this,event);return ok; }
  }
  window.__t3HudBridge = {
    permission(result) { permission=result; pendingPermission.splice(0).forEach(resolve=>resolve(result)); },
    click(id) { entries.get(id)?.dispatchEvent(new Event('click')); },
    reset() { entries.clear(); }
  };
  Object.defineProperty(window, 'Notification', {value:HUDNotification,configurable:true,writable:true});
  let lastBadge;
  const observe = () => {
    const href=document.querySelector('link[rel="icon"]')?.getAttribute('href') ?? '';
    const badge=href.startsWith('data:image/png;base64,') ? href : '';
    if(badge!==lastBadge){ lastBadge=badge;send({op:'badge',image:badge}); }
  };
  const start=()=>{new MutationObserver(observe).observe(document.head,{subtree:true,childList:true,attributes:true,attributeFilter:['href','rel']});observe();};
  if(document.head)start();else document.addEventListener('DOMContentLoaded',start,{once:true});
  for(const event of ['focus','blur','visibilitychange'])addEventListener(event,()=>send({op:'state',event,visible:document.visibilityState,focused:document.hasFocus()}));
  send({op:'ready',permission,visible:document.visibilityState,focused:document.hasFocus()});
})();
