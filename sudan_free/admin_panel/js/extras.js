// ═══ Posts, Requests, Ads Module ═══
const AdminExtras = {
  allPosts: [],
  allRequests: [],

  // ── Posts ──
  async loadPosts() {
    const snap = await db.collection('posts').orderBy('createdAt','desc').limit(100).get();
    this.allPosts = snap.docs.map(d => ({ id:d.id, ...d.data() }));
    this.renderPosts(this.allPosts);
  },
  renderPosts(posts) {
    document.getElementById('posts-count').textContent = `${posts.length} منشور`;
    const el = document.getElementById('posts-list');
    if (!posts.length) { el.innerHTML = '<p class="empty-state">لا توجد منشورات</p>'; return; }
    el.innerHTML = posts.map(p => {
      const imgs = p.allImageUrls || (p.imageUrl ? [p.imageUrl] : []);
      return `<div class="post-item">
        <div class="post-header">
          <div class="post-user-info">
            <img src="${p.userImageUrl || 'https://ui-avatars.com/api/?name='+encodeURIComponent(p.userName||'?')+'&background=6c5ce7&color=fff'}" alt="">
            <div><div class="name">${p.userName||'مستخدم'} ${p.isUserVerified?'<span class="verified-badge material-icons-outlined">verified</span>':''}</div><div class="meta">${timeAgo(p.createdAt)} — ${p.category||''}</div></div>
          </div>
          ${p.isPinned?'<span class="report-status active">مثبت</span>':''}
        </div>
        ${p.caption?`<div class="post-body">${p.caption.substring(0,200)}${p.caption.length>200?'...':''}</div>`:''}
        ${imgs.length?`<div class="post-images">${imgs.slice(0,3).map(u=>`<img src="${u}" onclick="AdminApp.previewImage('${u}')">`).join('')}${imgs.length>3?`<span style="color:var(--text-muted);align-self:center">+${imgs.length-3}</span>`:''}</div>`:''}
        <div class="post-stats">
          <span><span class="material-icons-outlined" style="font-size:16px">favorite</span>${p.totalReactions||0}</span>
          <span><span class="material-icons-outlined" style="font-size:16px">chat_bubble</span>${p.commentsCount||0}</span>
          <span><span class="material-icons-outlined" style="font-size:16px">share</span>${p.sharesCount||0}</span>
        </div>
        <div class="post-actions">
          <button class="btn btn-sm btn-ghost" onclick="AdminExtras.togglePin('${p.id}',${!p.isPinned})">${p.isPinned?'إلغاء التثبيت':'تثبيت'}</button>
          <button class="btn btn-sm btn-danger" onclick="AdminExtras.deletePost('${p.id}')">حذف</button>
        </div>
      </div>`;
    }).join('');
  },
  filterPosts() {
    const q = document.getElementById('posts-search').value.toLowerCase();
    const f = document.getElementById('posts-filter').value;
    let list = this.allPosts;
    if (q) list = list.filter(p => (p.caption||'').toLowerCase().includes(q) || (p.userName||'').toLowerCase().includes(q));
    if (f === 'pinned') list = list.filter(p => p.isPinned);
    if (f === 'reported') list = list.filter(p => (p.reportsCount||0) > 0);
    this.renderPosts(list);
  },
  async togglePin(id, pin) {
    await db.collection('posts').doc(id).update({ isPinned: pin });
    showToast(pin ? 'تم تثبيت المنشور' : 'تم إلغاء التثبيت');
    this.loadPosts();
  },
  async deletePost(id) {
    if (!confirm('حذف هذا المنشور نهائياً؟')) return;
    await db.collection('posts').doc(id).delete();
    showToast('تم حذف المنشور');
    this.loadPosts();
  },

  // ── Requests ──
  async loadRequests() {
    const snap = await db.collection('requests').orderBy('createdAt','desc').limit(100).get();
    this.allRequests = snap.docs.map(d => ({ id:d.id, ...d.data() }));
    this.renderRequests(this.allRequests);
  },
  renderRequests(reqs) {
    document.getElementById('requests-count').textContent = `${reqs.length} طلب`;
    const el = document.getElementById('requests-list');
    if (!reqs.length) { el.innerHTML = '<p class="empty-state">لا توجد طلبات</p>'; return; }
    el.innerHTML = reqs.map(r => {
      const imgs = r.imageUrls || (r.imageUrl ? [r.imageUrl] : []);
      const status = r.isFulfilled ? 'fulfilled' : 'active';
      return `<div class="request-item">
        <div class="request-header">
          <div class="post-user-info">
            <img src="${r.clientImageUrl || 'https://ui-avatars.com/api/?name='+encodeURIComponent(r.clientName||'?')+'&background=6c5ce7&color=fff'}" alt="">
            <div><div class="name">${r.clientName||'عميل'}</div><div class="meta">${timeAgo(r.createdAt)}${r.category?' — '+r.category:''}</div></div>
          </div>
          <span class="report-status ${status}">${r.isFulfilled?'مكتمل':'نشط'}</span>
        </div>
        <div class="request-body">${r.text||''}</div>
        ${imgs.length?`<div class="post-images">${imgs.map(u=>`<img src="${u}" onclick="AdminApp.previewImage('${u}')">`).join('')}</div>`:''}
        ${r.state?`<div style="color:var(--text-muted);font-size:12px;margin-bottom:8px"><span class="material-icons-outlined" style="font-size:14px;vertical-align:middle">location_on</span> ${r.locality||''} ${r.state}</div>`:''}
        <div style="display:flex;justify-content:space-between;align-items:center">
          <span style="color:var(--primary);font-size:13px;font-weight:600">${r.offersCount||0} عروض</span>
          <button class="btn btn-sm btn-danger" onclick="AdminExtras.deleteRequest('${r.id}')">حذف</button>
        </div>
      </div>`;
    }).join('');
  },
  filterRequests() {
    const f = document.getElementById('requests-filter').value;
    let list = this.allRequests;
    if (f === 'active') list = list.filter(r => !r.isFulfilled);
    if (f === 'fulfilled') list = list.filter(r => r.isFulfilled);
    this.renderRequests(list);
  },
  async deleteRequest(id) {
    if (!confirm('حذف هذا الطلب نهائياً؟')) return;
    await db.collection('requests').doc(id).delete();
    showToast('تم حذف الطلب');
    this.loadRequests();
  },

  // ── Ads ──
  async loadAds() {
    const snap = await db.collection('ads').orderBy('expiryDate','desc').get();
    const el = document.getElementById('ads-list');
    if (snap.empty) { el.innerHTML = '<p class="empty-state">لا توجد إعلانات</p>'; return; }
    el.innerHTML = snap.docs.map(d => {
      const a = d.data();
      const expired = a.expiryDate && a.expiryDate.toDate() < new Date();
      return `<div class="ad-item">
        ${a.imageUrl?`<img src="${a.imageUrl}" onclick="AdminApp.previewImage('${a.imageUrl}')">`:'<div style="width:80px;height:60px;background:var(--bg);border-radius:8px;display:flex;align-items:center;justify-content:center"><span class="material-icons-outlined" style="color:var(--text-muted)">image</span></div>'}
        <div class="ad-info">
          <h4>${a.title||'إعلان'} ${expired?'<span style="color:var(--danger);font-size:11px">(منتهي)</span>':''}</h4>
          <p>${a.description||''}</p>
          <div class="ad-meta">
            <span>${a.isActive?'✅ نشط':'⏸ معطل'}</span>
            <span>📍 ${a.targetRegion||'الكل'}</span>
            <span>👥 ${ROLE_NAMES[a.targetProfession]||'الكل'}</span>
            <span>⭐ أولوية ${a.priority||0}</span>
          </div>
        </div>
        <div style="display:flex;flex-direction:column;gap:6px">
          <button class="btn btn-sm ${a.isActive?'btn-warning':'btn-success'}" onclick="AdminExtras.toggleAd('${d.id}',${!a.isActive})">${a.isActive?'تعطيل':'تفعيل'}</button>
          <button class="btn btn-sm btn-danger" onclick="AdminExtras.deleteAd('${d.id}')">حذف</button>
        </div>
      </div>`;
    }).join('');
  },
  async createAd() {
    const title = document.getElementById('ad-title').value.trim();
    const desc = document.getElementById('ad-description').value.trim();
    const img = document.getElementById('ad-image').value.trim();
    const link = document.getElementById('ad-link').value.trim();
    const region = document.getElementById('ad-region').value;
    const prof = document.getElementById('ad-profession').value;
    const priority = parseInt(document.getElementById('ad-priority').value) || 5;
    const expiry = document.getElementById('ad-expiry').value;
    if (!title) { showToast('أدخل عنوان الإعلان','error'); return; }
    if (!expiry) { showToast('حدد تاريخ الانتهاء','error'); return; }
    await db.collection('ads').add({
      title, description: desc, imageUrl: img, actionUrl: link,
      targetRegion: region, targetProfession: prof, priority,
      isActive: true,
      expiryDate: firebase.firestore.Timestamp.fromDate(new Date(expiry)),
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('تم إنشاء الإعلان بنجاح');
    ['ad-title','ad-description','ad-image','ad-link','ad-expiry'].forEach(id => document.getElementById(id).value = '');
    this.loadAds();
  },
  async toggleAd(id, active) {
    await db.collection('ads').doc(id).update({ isActive: active });
    showToast(active ? 'تم تفعيل الإعلان' : 'تم تعطيل الإعلان');
    this.loadAds();
  },
  async deleteAd(id) {
    if (!confirm('حذف هذا الإعلان نهائياً؟')) return;
    await db.collection('ads').doc(id).delete();
    showToast('تم حذف الإعلان');
    this.loadAds();
  }
};
// Expose filter functions globally
window.AdminExtras = AdminExtras;
