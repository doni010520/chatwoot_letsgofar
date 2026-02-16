<template>
  <div 
    class="group relative w-full cursor-pointer overflow-hidden rounded-lg bg-slate-800 shadow-lg transition-all hover:-translate-y-1 hover:shadow-xl hover:border-slate-600 border border-transparent"
    :class="[
      cardBorderClass, 
      { 'z-50 rotate-2 scale-105 opacity-90 ring-2 ring-blue-500/50': isDragging }
    ]"
    draggable="true"
    @click="$emit('click')"
    @dragstart="onDragStart"
    @dragend="onDragEnd"
  >
    
    <!-- Decoração de Fundo (Gradient Sutil) -->
    <div class="pointer-events-none absolute right-0 top-0 h-24 w-24 rounded-bl-full bg-white/5 transition-opacity group-hover:bg-white/10"></div>

    <!-- Botão de Remover (Aparece no Hover) -->
    <button 
      class="absolute right-2 top-2 z-20 rounded p-1.5 text-slate-500 opacity-0 hover:bg-red-500/20 hover:text-red-400 transition-all group-hover:opacity-100"
      title="Remover do CRM"
      @click.stop="confirmRemove"
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18"/><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>
    </button>

    <!-- Conteúdo Principal -->
    <div class="p-4 pb-2 relative z-10">
      
      <!-- Linha Superior: Status e Tempo -->
      <div class="mb-3 flex items-center justify-between pr-6">
        <span 
          class="flex items-center gap-1.5 rounded-full px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide border"
          :class="statusBadgeClasses"
        >
          <span class="h-1.5 w-1.5 rounded-full" :class="statusDotClass"></span>
          {{ statusLabel }}
        </span>
        
        <div class="flex items-center gap-1 text-[10px] font-medium text-slate-500">
          <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>
          <span v-if="timeAgo">{{ timeAgo }}</span>
        </div>
      </div>

      <!-- Cabeçalho: Avatar + Nome -->
      <div class="mb-4 flex items-center gap-3">
        <!-- Avatar -->
        <div class="relative flex-shrink-0">
          <img
            v-if="contactThumbnail"
            :src="contactThumbnail"
            :alt="contactName"
            class="h-12 w-12 rounded-full border-2 border-slate-700 object-cover shadow-sm"
          />
          <div v-else class="flex h-12 w-12 items-center justify-center rounded-full border-2 border-slate-700 bg-slate-700 text-sm font-bold text-slate-300">
            {{ getInitials(contactName) }}
          </div>
          <!-- Indicador Online/Status (Opcional) -->
          <div class="absolute bottom-0 right-0 h-3 w-3 rounded-full border-2 border-slate-800 bg-green-500"></div>
        </div>

        <!-- Nome e Telefone -->
        <div class="min-w-0 flex-1">
          <h3 class="truncate text-lg font-bold leading-tight text-white" :title="contactName">
            {{ contactName }}
          </h3>
          <div class="mt-0.5 flex items-center gap-1.5 text-xs text-slate-400">
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="opacity-70"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
            <span class="truncate">{{ contactPhone || 'Sem telefone' }}</span>
          </div>
        </div>
      </div>

      <!-- Grid de Informações (Valor + Extras) -->
      <div class="mt-3 mb-2 grid grid-cols-2 gap-x-4 gap-y-3 pl-1">
        <!-- Valor (Sempre em destaque se existir) -->
        <div v-if="item.deal_value" class="min-w-0">
          <p class="mb-0.5 text-[10px] font-semibold uppercase tracking-wider text-slate-500">Valor</p>
          <p class="truncate text-sm font-bold text-green-400">{{ formatCurrency(item.deal_value) }}</p>
        </div>

        <!-- Loop Dinâmico para TODOS os Campos Personalizados Visíveis -->
        <div 
          v-for="field in visibleCustomFields" 
          :key="field.field_key"
          class="min-w-0"
        >
           <p class="mb-0.5 text-[10px] font-semibold uppercase tracking-wider text-slate-500 truncate" :title="field.name">
             {{ field.name }}
           </p>
           <p class="truncate text-sm font-medium text-slate-300" :title="formatFieldValue(field)">
             {{ formatFieldValue(field) }}
           </p>
        </div>
      </div>
      
      <!-- Tarefas (Pílula Condensada) -->
      <div v-if="hasTasks" class="mt-3 flex items-center gap-2 rounded bg-slate-900/50 px-2 py-1.5 text-xs text-slate-400 border border-slate-700/50">
        <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>
        <span>{{ item.tasks.pending }} tarefa{{ item.tasks.pending > 1 ? 's' : '' }}</span>
        <span v-if="item.tasks.overdue > 0" class="font-bold text-red-400 ml-auto">
           {{ item.tasks.overdue }} atrasada{{ item.tasks.overdue > 1 ? 's' : '' }}
        </span>
      </div>

      <!-- Atribuído a (Rodapé Interno) -->
      <div v-if="item.assignee" class="mt-2 flex items-center justify-end">
         <span class="text-[10px] text-slate-600 mr-2">Atribuído a</span>
         <span class="text-xs text-slate-400 font-medium">{{ item.assignee.name }}</span>
      </div>

    </div>

    <!-- RODAPÉ DE AÇÕES (Híbrido) -->
    
    <!-- Estado: Já Finalizado (Ganho/Perdido) -->
    <div 
      v-if="item.closed_won !== null && item.closed_won !== undefined" 
      class="mt-auto border-t py-2 text-center text-xs font-bold uppercase tracking-wider"
      :class="item.closed_won ? 'border-green-500/20 bg-green-500/10 text-green-400' : 'border-red-500/20 bg-red-500/10 text-red-400'"
    >
      {{ item.closed_won ? '✓ Negócio Ganho' : '✗ Negócio Perdido' }}
    </div>

    <!-- Estado: Aberto (Botões de Ação) -->
    <div 
      v-else 
      class="mt-auto flex divide-x divide-slate-700/80 border-t border-slate-700/80 bg-slate-900/30"
    >
      <button 
        class="group/btn flex flex-1 items-center justify-center gap-2 py-3 text-xs font-bold text-green-500 transition-colors hover:bg-green-500/10"
        title="Marcar como Ganho"
        @click.stop="markAsWon"
      >
        <svg class="h-4 w-4 transition-transform group-hover/btn:scale-110" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
        GANHO
      </button>
      
      <button 
        class="group/btn flex flex-1 items-center justify-center gap-2 py-3 text-xs font-bold text-red-400 transition-colors hover:bg-red-500/10"
        title="Marcar como Perdido"
        @click.stop="markAsLost"
      >
        <svg class="h-4 w-4 transition-transform group-hover/btn:scale-110" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
        PERDIDO
      </button>
    </div>

    <!-- MODAL (Mantido simples, apenas estilizado para dark mode) -->
    <div v-if="showLossReasonModal" class="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm" @click.stop="closeLossModal">
      <div class="w-full max-w-sm rounded-lg bg-slate-800 p-6 shadow-2xl border border-slate-700" @click.stop>
        <h4 class="mb-4 text-lg font-bold text-white">Motivo da Perda</h4>
        
        <div class="mb-4">
            <select v-model="selectedLossReason" class="w-full rounded bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2 text-sm focus:border-green-500 focus:outline-none focus:ring-1 focus:ring-green-500">
            <option value="" disabled>Selecione um motivo...</option>
            <option value="Preço">Preço</option>
            <option value="Concorrência">Concorrência</option>
            <option value="Timing">Timing / Não é o momento</option>
            <option value="Sem resposta">Sem resposta</option>
            <option value="Desistiu">Desistiu</option>
            <option value="Outro">Outro</option>
            </select>
        </div>

        <div v-if="selectedLossReason === 'Outro'" class="mb-4">
            <input
            v-model="customLossReason"
            type="text"
            placeholder="Especifique o motivo..."
            class="w-full rounded bg-slate-900 border border-slate-700 text-slate-200 px-3 py-2 text-sm focus:border-green-500 focus:outline-none"
            />
        </div>

        <div class="flex justify-end gap-2">
          <button class="rounded px-4 py-2 text-sm text-slate-400 hover:bg-slate-700 hover:text-white transition-colors" @click.stop="closeLossModal">
            Cancelar
          </button>
          <button 
            class="rounded bg-red-600 px-4 py-2 text-sm font-medium text-white hover:bg-red-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            :disabled="!canConfirmLoss"
            @click.stop="confirmLoss"
          >
            Confirmar Perda
          </button>
        </div>
      </div>
    </div>

  </div>
</template>

<script>
export default {
  name: 'KanbanCard',
  props: {
    item: { type: Object, required: true },
    itemType: { type: String, default: 'conversation' },
    customFieldsConfig: { type: Array, default: () => [] },
  },
  emits: ['click', 'dragstart', 'mark-won', 'mark-lost', 'remove'],
  data() {
    return {
      isDragging: false,
      showLossReasonModal: false,
      selectedLossReason: '',
      customLossReason: '',
    };
  },
  computed: {
    // --- Lógica de Visualização ---
    cardBorderClass() {
        // Borda esquerda colorida baseada no status
        if (this.item.closed_won === true) return 'border-l-4 border-l-green-500';
        if (this.item.closed_won === false) return 'border-l-4 border-l-red-500';
        
        // Cores por status quando em aberto
        const statusColors = {
            'open': 'border-l-4 border-l-blue-500',
            'pending': 'border-l-4 border-l-yellow-500',
            'resolved': 'border-l-4 border-l-purple-500',
            'snoozed': 'border-l-4 border-l-slate-500'
        };
        return statusColors[this.item.status] || 'border-l-4 border-l-blue-500';
    },
    statusBadgeClasses() {
        const maps = {
            'open': 'bg-blue-500/10 text-blue-400 border-blue-500/20',
            'pending': 'bg-yellow-500/10 text-yellow-400 border-yellow-500/20',
            'resolved': 'bg-purple-500/10 text-purple-400 border-purple-500/20',
            'snoozed': 'bg-slate-500/10 text-slate-400 border-slate-500/20',
        };
        return maps[this.item.status] || 'bg-slate-700 text-slate-300 border-slate-600';
    },
    statusDotClass() {
         const maps = {
            'open': 'bg-blue-500',
            'pending': 'bg-yellow-500',
            'resolved': 'bg-purple-500',
            'snoozed': 'bg-slate-500',
        };
        return maps[this.item.status] || 'bg-slate-400';
    },
    // --- Dados do Contato ---
    contactName() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.name || 'Sem nome';
      }
      return this.item.name || 'Sem nome';
    },
    contactPhone() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.phone_number || this.item.contact?.email || '';
      }
      return this.item.phone_number || this.item.email || '';
    },
    contactThumbnail() {
      if (this.itemType === 'conversation') {
        return this.item.contact?.thumbnail || this.item.contact?.avatar_url || null;
      }
      return this.item.thumbnail || this.item.avatar_url || null;
    },
    statusLabel() {
      const statuses = {
        open: 'Aberto',
        resolved: 'Resolvido',
        pending: 'Pendente',
        snoozed: 'Adiado',
      };
      return statuses[this.item.status] || this.item.status;
    },
    timeAgo() {
      const date = this.item.last_activity_at;
      if (!date) return null;
      
      const now = new Date();
      const past = new Date(date);
      const diffMs = now - past;
      const diffMins = Math.floor(diffMs / 60000);
      const diffHours = Math.floor(diffMins / 60);
      const diffDays = Math.floor(diffHours / 24);

      if (diffMins < 1) return 'Agora';
      if (diffMins < 60) return `${diffMins}m`;
      if (diffHours < 24) return `${diffHours}h`;
      if (diffDays < 7) return `${diffDays}d`;
      return past.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit' });
    },
    hasTasks() {
      return this.item.tasks && this.item.tasks.pending > 0;
    },
    visibleCustomFields() {
      if (this.item.custom_field_values && Array.isArray(this.item.custom_field_values)) {
        return this.item.custom_field_values.filter(f => f.show_on_card);
      }
      if (!this.item.custom_fields || !this.customFieldsConfig) return [];
      
      return this.customFieldsConfig
        .filter(field => field.show_on_card && this.item.custom_fields[field.field_key])
        .map(field => ({
          ...field,
          value: this.item.custom_fields[field.field_key],
        }));
    },
    canConfirmLoss() {
      if (!this.selectedLossReason) return false;
      if (this.selectedLossReason === 'Outro' && !this.customLossReason.trim()) return false;
      return true;
    },
  },
  methods: {
    onDragStart(event) {
      this.isDragging = true;
      this.$emit('dragstart', event);
    },
    onDragEnd() {
      this.isDragging = false;
    },
    getInitials(name) {
      if (!name) return '?';
      return name
        .split(' ')
        .map(word => word[0])
        .join('')
        .substring(0, 2)
        .toUpperCase();
    },
    formatCurrency(value) {
      return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL',
      }).format(value);
    },
    formatFieldValue(field) {
      const value = field.value;
      if (!value) return '-';
      const fieldType = field.field_type || field.type;

      switch (fieldType) {
        case 'currency': return this.formatCurrency(parseFloat(value) || 0);
        case 'checkbox': return value === 'true' || value === true ? 'Sim' : 'Não';
        case 'date': return new Date(value).toLocaleDateString('pt-BR');
        case 'multiselect':
          try {
            const arr = JSON.parse(value);
            return Array.isArray(arr) ? arr.join(', ') : value;
          } catch { return value; }
        default: return value;
      }
    },
    markAsWon() {
      this.$emit('mark-won', { itemId: this.item.id, itemType: this.itemType });
    },
    markAsLost() {
      this.showLossReasonModal = true;
    },
    closeLossModal() {
      this.showLossReasonModal = false;
      this.selectedLossReason = '';
      this.customLossReason = '';
    },
    confirmLoss() {
      const reason = this.selectedLossReason === 'Outro' 
        ? this.customLossReason.trim() 
        : this.selectedLossReason;
      
      this.$emit('mark-lost', { 
        itemId: this.item.id, 
        itemType: this.itemType,
        reason: reason
      });
      this.closeLossModal();
    },
    confirmRemove() {
      if (confirm('Remover este card do CRM? A conversa não será apagada.')) {
        this.$emit('remove', { itemId: this.item.id, itemType: this.itemType });
      }
    },
  },
};
</script>

<style scoped>
/* Se você NÃO estiver usando Tailwind no projeto, precisará adicionar o CDN no index.html 
  ou converter essas classes para CSS puro. 
  
  Mantive este bloco vazio propositalmente para mostrar que o estilo 
  agora é 100% controlado pelas classes do template acima.
*/
</style>

