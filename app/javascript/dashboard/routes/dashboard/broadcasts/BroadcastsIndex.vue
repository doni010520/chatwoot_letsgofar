<script setup>
import { ref, computed, onMounted, onBeforeUnmount } from 'vue';
import { useStore } from 'vuex';

const store = useStore();

const view = ref('list'); // 'list' | 'new' | 'detail'
const selectedId = ref(null);
const isSaving = ref(false);
const errorMsg = ref('');
const fileName = ref('');
let selectedFile = null;
let pollTimer = null;

const broadcasts = computed(() => store.getters['broadcasts/getBroadcasts']);
const current = computed(() => store.getters['broadcasts/getCurrent']);

const form = ref({
  title: '',
  message_template: '',
  min_minutes: 5,
  max_minutes: 6,
  send_window_start: 9,
  send_window_end: 18,
  daily_cap: 50,
});

const STATUS = {
  draft: { label: 'Rascunho', color: 'bg-n-slate-4 text-n-slate-11' },
  running: { label: 'Enviando', color: 'bg-n-brand/10 text-n-brand' },
  paused: { label: 'Pausado', color: 'bg-amber-100 text-amber-700' },
  completed: { label: 'Concluído', color: 'bg-green-100 text-green-700' },
  cancelled: { label: 'Cancelado', color: 'bg-n-slate-4 text-n-slate-11' },
};

const statusInfo = status => STATUS[status] || { label: status, color: '' };

const progress = b => {
  if (!b || !b.total_count) return 0;
  return Math.round(((b.sent_count + b.failed_count) / b.total_count) * 100);
};

const messageRef = ref(null);
const insertVar = token => {
  form.value.message_template += token;
};

const fetchAll = () => store.dispatch('broadcasts/fetch');

const goNew = () => {
  errorMsg.value = '';
  fileName.value = '';
  selectedFile = null;
  form.value = {
    title: '',
    message_template: '',
    min_minutes: 5,
    max_minutes: 6,
    send_window_start: 9,
    send_window_end: 18,
    daily_cap: 50,
  };
  view.value = 'new';
};

const onFileChange = event => {
  const file = event.target.files?.[0];
  if (file) {
    selectedFile = file;
    fileName.value = file.name;
  }
};

const downloadTemplate = () => {
  const csv = 'telefone,nome,merge1,merge2\n5511999998888,Vinícius Cabral,inglês para carreira,agosto\n';
  const blob = new Blob(['﻿' + csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'modelo-disparo.csv';
  a.click();
  URL.revokeObjectURL(url);
};

const handleCreate = async () => {
  errorMsg.value = '';
  if (!form.value.title.trim() || !form.value.message_template.trim()) {
    errorMsg.value = 'Preencha o nome e a mensagem.';
    return;
  }
  if (!selectedFile) {
    errorMsg.value = 'Envie a planilha CSV de contatos.';
    return;
  }
  isSaving.value = true;
  try {
    const payload = {
      title: form.value.title,
      message_template: form.value.message_template,
      min_interval: Math.round(form.value.min_minutes * 60),
      max_interval: Math.round(form.value.max_minutes * 60),
      send_window_start: form.value.send_window_start,
      send_window_end: form.value.send_window_end,
      daily_cap: form.value.daily_cap,
    };
    const created = await store.dispatch('broadcasts/create', payload);
    await store.dispatch('broadcasts/uploadContacts', {
      id: created.id,
      file: selectedFile,
    });
    selectedId.value = created.id;
    await store.dispatch('broadcasts/show', created.id);
    view.value = 'detail';
  } catch (error) {
    errorMsg.value =
      error?.response?.data?.error ||
      error?.response?.data?.errors?.join(', ') ||
      'Erro ao criar o disparo.';
  } finally {
    isSaving.value = false;
  }
};

const openDetail = async id => {
  selectedId.value = id;
  await store.dispatch('broadcasts/show', id);
  view.value = 'detail';
  startPolling();
};

const backToList = () => {
  stopPolling();
  view.value = 'list';
  fetchAll();
};

const handleStart = async () => {
  errorMsg.value = '';
  try {
    await store.dispatch('broadcasts/start', selectedId.value);
    startPolling();
  } catch (error) {
    errorMsg.value = error?.response?.data?.error || 'Não foi possível iniciar.';
  }
};

const handlePause = () => store.dispatch('broadcasts/pause', selectedId.value);
const handleCancel = async () => {
  if (window.confirm('Cancelar este disparo? Os contatos ainda não enviados não receberão a mensagem.')) {
    await store.dispatch('broadcasts/cancel', selectedId.value);
  }
};

const startPolling = () => {
  stopPolling();
  pollTimer = setInterval(() => {
    if (selectedId.value && current.value?.status === 'running') {
      store.dispatch('broadcasts/show', selectedId.value);
    }
  }, 8000);
};
const stopPolling = () => {
  if (pollTimer) clearInterval(pollTimer);
  pollTimer = null;
};

onMounted(fetchAll);
onBeforeUnmount(stopPolling);
</script>

<template>
  <div class="flex flex-col w-full h-full overflow-auto bg-n-background">
    <!-- Header -->
    <div class="flex items-center justify-between px-6 py-4 border-b border-n-weak">
      <div class="flex items-center gap-2">
        <button
          v-if="view !== 'list'"
          class="text-sm text-n-slate-11 hover:text-n-slate-12"
          @click="backToList"
        >
          ← Voltar
        </button>
        <h1 class="text-lg font-semibold text-n-slate-12">Disparos</h1>
      </div>
      <button
        v-if="view === 'list'"
        class="px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-brand hover:opacity-90"
        @click="goNew"
      >
        + Novo disparo
      </button>
    </div>

    <!-- LISTA -->
    <div v-if="view === 'list'" class="p-6 space-y-3">
      <p v-if="!broadcasts.length" class="text-sm text-n-slate-10">
        Nenhum disparo ainda. Clique em "Novo disparo" para começar.
      </p>
      <button
        v-for="b in broadcasts"
        :key="b.id"
        class="flex items-center justify-between w-full p-4 text-left border rounded-lg border-n-weak hover:bg-n-slate-2"
        @click="openDetail(b.id)"
      >
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2">
            <span class="font-medium truncate text-n-slate-12">{{ b.title }}</span>
            <span class="px-2 py-0.5 text-xs rounded-full" :class="statusInfo(b.status).color">
              {{ statusInfo(b.status).label }}
            </span>
          </div>
          <div class="mt-2 w-full h-1.5 rounded-full bg-n-slate-4 overflow-hidden">
            <div class="h-full bg-n-brand" :style="{ width: progress(b) + '%' }" />
          </div>
        </div>
        <div class="ml-4 text-xs text-right text-n-slate-10 shrink-0">
          {{ b.sent_count }}/{{ b.total_count }} enviados
          <span v-if="b.failed_count">· {{ b.failed_count }} falhas</span>
        </div>
      </button>
    </div>

    <!-- NOVO -->
    <div v-else-if="view === 'new'" class="max-w-2xl p-6 space-y-4">
      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">Nome do disparo</label>
        <input
          v-model="form.title"
          type="text"
          placeholder="Ex.: Retomada agosto"
          class="w-full px-3 py-2 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12"
        />
      </div>

      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">Mensagem</label>
        <div class="flex flex-wrap gap-1 mb-1">
          <button
            v-for="tk in ['{primeiro_nome}', '{nome}', '{merge1}', '{merge2}']"
            :key="tk"
            type="button"
            class="px-2 py-0.5 text-xs rounded border border-n-weak text-n-slate-11 hover:bg-n-slate-2"
            @click="insertVar(tk)"
          >
            {{ tk }}
          </button>
        </div>
        <textarea
          ref="messageRef"
          v-model="form.message_template"
          rows="6"
          placeholder="Oi {primeiro_nome}! {Tudo bem?|Como você está?} Aqui é a Luana, da Let's Go Far..."
          class="w-full px-3 py-2 text-sm border rounded-lg resize-none border-n-weak bg-n-background text-n-slate-12"
        />
        <p class="mt-1 text-xs text-n-slate-10">
          Use <code>{primeiro_nome}</code> para o nome. Para variar sem mudar o sentido, escreva alternativas entre chaves separadas por barra: <code>{Oi|Olá}</code> — cada contato recebe uma combinação.
        </p>
      </div>

      <div>
        <label class="block mb-1 text-sm font-medium text-n-slate-12">Planilha de contatos (CSV)</label>
        <div class="flex items-center gap-3">
          <input type="file" accept=".csv,text/csv" class="text-sm text-n-slate-11" @change="onFileChange" />
          <button type="button" class="text-xs underline text-n-brand" @click="downloadTemplate">
            baixar modelo
          </button>
        </div>
        <p v-if="fileName" class="mt-1 text-xs text-n-slate-11">Selecionado: {{ fileName }}</p>
        <p class="mt-1 text-xs text-n-slate-10">
          Colunas: <code>telefone</code> (com DDI 55), <code>nome</code>, e opcionalmente <code>merge1</code>, <code>merge2</code>.
        </p>
      </div>

      <div class="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-11">Intervalo mín. (min)</label>
          <input v-model.number="form.min_minutes" type="number" min="1" class="w-full px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12" />
        </div>
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-11">Intervalo máx. (min)</label>
          <input v-model.number="form.max_minutes" type="number" min="1" class="w-full px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12" />
        </div>
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-11">Janela (início-fim)</label>
          <div class="flex items-center gap-1">
            <input v-model.number="form.send_window_start" type="number" min="0" max="23" class="w-full px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12" />
            <input v-model.number="form.send_window_end" type="number" min="0" max="23" class="w-full px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12" />
          </div>
        </div>
        <div>
          <label class="block mb-1 text-xs font-medium text-n-slate-11">Teto por dia</label>
          <input v-model.number="form.daily_cap" type="number" min="1" class="w-full px-2 py-1.5 text-sm border rounded-lg border-n-weak bg-n-background text-n-slate-12" />
        </div>
      </div>

      <p v-if="errorMsg" class="text-sm text-ruby-11">{{ errorMsg }}</p>

      <div class="flex justify-end gap-2 pt-2">
        <button class="px-4 py-2 text-sm rounded-lg text-n-slate-11 hover:bg-n-slate-2" @click="backToList">Cancelar</button>
        <button
          class="px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-brand hover:opacity-90 disabled:opacity-50"
          :disabled="isSaving"
          @click="handleCreate"
        >
          {{ isSaving ? 'Salvando...' : 'Criar rascunho' }}
        </button>
      </div>
    </div>

    <!-- DETALHE -->
    <div v-else-if="view === 'detail' && current" class="max-w-3xl p-6 space-y-5">
      <div class="flex items-center gap-3">
        <h2 class="text-base font-semibold text-n-slate-12">{{ current.title }}</h2>
        <span class="px-2 py-0.5 text-xs rounded-full" :class="statusInfo(current.status).color">
          {{ statusInfo(current.status).label }}
        </span>
      </div>

      <!-- progresso -->
      <div>
        <div class="w-full h-2 overflow-hidden rounded-full bg-n-slate-4">
          <div class="h-full bg-n-brand" :style="{ width: progress(current) + '%' }" />
        </div>
        <div class="flex gap-4 mt-2 text-sm text-n-slate-11">
          <span>Total: {{ current.total_count }}</span>
          <span class="text-green-600">Enviados: {{ current.sent_count }}</span>
          <span class="text-amber-600">Pendentes: {{ current.pending_count }}</span>
          <span v-if="current.failed_count" class="text-ruby-11">Falhas: {{ current.failed_count }}</span>
        </div>
      </div>

      <p v-if="errorMsg" class="text-sm text-ruby-11">{{ errorMsg }}</p>

      <!-- ações -->
      <div class="flex gap-2">
        <button
          v-if="['draft', 'paused'].includes(current.status)"
          class="px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-brand hover:opacity-90"
          @click="handleStart"
        >
          {{ current.status === 'paused' ? 'Retomar' : 'Iniciar disparo' }}
        </button>
        <button
          v-if="current.status === 'running'"
          class="px-4 py-2 text-sm font-medium border rounded-lg border-n-weak text-n-slate-12 hover:bg-n-slate-2"
          @click="handlePause"
        >
          Pausar
        </button>
        <button
          v-if="['draft', 'running', 'paused'].includes(current.status)"
          class="px-4 py-2 text-sm font-medium rounded-lg text-ruby-11 hover:bg-ruby-2"
          @click="handleCancel"
        >
          Cancelar
        </button>
      </div>

      <!-- mensagem -->
      <div class="p-3 text-sm border rounded-lg border-n-weak bg-n-slate-2 text-n-slate-11 whitespace-pre-wrap">
        {{ current.message_template }}
      </div>

      <!-- lista de destinatários -->
      <div class="border rounded-lg border-n-weak">
        <div class="px-3 py-2 text-xs font-medium border-b border-n-weak text-n-slate-11">
          Contatos ({{ current.recipients ? current.recipients.length : 0 }})
        </div>
        <div class="overflow-auto max-h-80">
          <div
            v-for="r in current.recipients"
            :key="r.id"
            class="flex items-center justify-between px-3 py-2 text-sm border-b border-n-weak last:border-0"
          >
            <div class="min-w-0">
              <span class="text-n-slate-12">{{ r.name || '—' }}</span>
              <span class="ml-2 text-xs text-n-slate-10">{{ r.phone }}</span>
              <span v-if="r.error" class="ml-2 text-xs text-ruby-11">{{ r.error }}</span>
            </div>
            <span
              class="px-2 py-0.5 text-xs rounded-full"
              :class="{
                'bg-green-100 text-green-700': r.status === 'sent',
                'bg-amber-100 text-amber-700': r.status === 'pending',
                'bg-ruby-3 text-ruby-11': r.status === 'failed',
              }"
            >
              {{ { sent: 'enviado', pending: 'pendente', failed: 'falha', skipped: 'pulado' }[r.status] }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
