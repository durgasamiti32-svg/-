/* Durga Samiti: Supabase Auth + shared JSON state + Realtime.
   Only the Supabase publishable/anon key belongs in config.js. */
(function () {
  "use strict";
  const cfg = window.DURGA_SUPABASE_CONFIG || {};
  if (!window.supabase || !cfg.url || !cfg.publishableKey || cfg.publishableKey.includes("PASTE_YOUR_")) {
    window.DurgaCloud = {
      ready: false,
      login: async () => { throw new Error("config.js-এ Supabase Project URL ও Publishable Key বসান।"); },
      load: async () => null,
      save: async () => { throw new Error("Supabase configuration missing"); },
      subscribe: () => {}
    };
    return;
  }

  const client = window.supabase.createClient(cfg.url, cfg.publishableKey, {
    auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true }
  });
  const TABLE = "durga_app_state";
  function authEmail(memberId) {
    const bytes = new TextEncoder().encode(String(memberId).trim().toLowerCase());
    let binary = "";
    bytes.forEach(b => binary += String.fromCharCode(b));
    const encoded = btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
    return `member-${encoded}@durga-samiti.invalid`;
  }
  function safeData(data) {
    const copy = JSON.parse(JSON.stringify(data || {}));
    if (Array.isArray(copy.members)) copy.members.forEach(m => { delete m.password; delete m.pass; delete m.password_hash; });
    return copy;
  }
  let channel = null;
  window.DurgaCloud = {
    ready: true,
    async login(memberId, password) {
      if (!memberId || !password) throw new Error("Member ID ও Password লিখুন।");
      const { data, error } = await client.auth.signInWithPassword({
        email: authEmail(memberId), password
      });
      if (error || !data.user) throw new Error("Member ID অথবা Password ভুল, অথবা Supabase Auth অ্যাকাউন্ট তৈরি করা হয়নি।");
      return data.user;
    },
    async load() {
      const { data, error } = await client.from(TABLE).select("data").eq("id", 1).maybeSingle();
      if (error) throw new Error("Database থেকে তথ্য পড়া যায়নি: " + error.message);
      return data ? safeData(data.data) : null;
    },
    async save(value) {
      const { data: sessionData } = await client.auth.getSession();
      if (!sessionData.session) return;
      const clean = safeData(value);
      const { error } = await client.from(TABLE).upsert({
        id: 1, data: clean, updated_at: new Date().toISOString()
      }, { onConflict: "id" });
      if (error) throw new Error("Database-এ সংরক্ষণ ব্যর্থ: " + error.message);
    },
    subscribe(callback) {
      if (channel) client.removeChannel(channel);
      channel = client.channel("durga-samiti-live-data")
        .on("postgres_changes", { event: "*", schema: "public", table: TABLE, filter: "id=eq.1" }, payload => {
          const next = payload.new && payload.new.data;
          if (next) callback(safeData(next));
        })
        .subscribe();
    },
    async logout() { await client.auth.signOut(); }
  };
})();
