// ===== CONFIGURE AQUI (Supabase > Project Settings > API) =====
const CFG={url:'COLE_A_PROJECT_URL',key:'COLE_A_ANON_PUBLIC_KEY',name:'Galeria Privada'};
// ===============================================================
const sb=supabase.createClient(CFG.url,CFG.key);
const $=s=>document.querySelector(s);
const esc=s=>String(s??'').replace(/[&<>"]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const out=async()=>{await sb.auth.signOut();location.reload()};
async function me(){const{data:{user}}=await sb.auth.getUser();if(!user)return null;const{data}=await sb.from('profiles').select('*').eq('id',user.id).single();return data}
function auth(el,done){
 el.innerHTML=`<div class="card auth"><h2>${CFG.name}</h2><p class="muted">Entre para acessar os álbuns liberados para você.</p><input id="n" placeholder="Seu nome" hidden><input id="e" type="email" placeholder="E-mail"><input id="p" type="password" placeholder="Senha (mínimo 8 caracteres)"><div class="msg" id="m"></div><button id="go" style="width:100%">Entrar</button><p style="text-align:center"><a href="#" id="tg">Criar conta</a></p></div>`;
 let reg=false;
 $('#tg').onclick=e=>{e.preventDefault();reg=!reg;$('#n').hidden=!reg;$('#go').textContent=reg?'Cadastrar':'Entrar';$('#tg').textContent=reg?'Já tenho conta':'Criar conta'};
 $('#go').onclick=async()=>{const e=$('#e').value,p=$('#p').value;
  const r=reg?await sb.auth.signUp({email:e,password:p,options:{data:{name:$('#n').value}}}):await sb.auth.signInWithPassword({email:e,password:p});
  if(r.error)return $('#m').textContent=r.error.message;
  if(!r.data.session)return $('#m').textContent='Confirme o e-mail enviado e depois entre.';
  done()}}
