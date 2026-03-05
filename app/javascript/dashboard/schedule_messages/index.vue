<template>
  <div class="scheduled-messages-container">
    <div class="header">
      <h1 class="title">📅 Mensagens Agendadas</h1>
    </div>

    <div class="filters">
      <input 
        v-model="filters.search" 
        placeholder="🔍 Buscar contato..."
        class="filter-input"
        @input="loadMessages"
      />
      <select v-model="filters.status" @change="loadMessages" class="filter-select">
        <option value="">Todos os status</option>
        <option value="pending">⏳ Pendentes</option>
        <option value="sent">✅ Enviadas</option>
        <option value="failed">❌ Falhadas</option>
      </select>
      <select v-model="filters.sortBy" @change="loadMessages" class="filter-select">
        <option value="date_asc">📅 Mais próximas</option>
        <option value="date_desc">📅 Mais distantes</option>
        <option value="contact">👤 Contato (A-Z)</option>
      </select>
    </div>

    <div v-if="loading" class="loading">Carregando...</div>
    
    <div v-else class="messages-grid">
      <div v-for="msg in messages" :key="msg.id" class="message-card">
        <div class="card-header">
          <div class="contact-info">
            <img :src="msg.contact.avatar || '/avatar-default.png'" class="avatar" />
            <span class="contact-name">{{ msg.contact.name }}</span>
          </div>
          <span class="status-badge" :class="`status-${msg.status}`">
            {{ statusLabel(msg.status) }}
          </span>
        </div>
        
        <div class="scheduled-time">
          📅 {{ formatDateTime(msg.scheduled_at) }}
        </div>
        
        <div class="message-content">{{ msg.content }}</div>
        
        <div class="card-actions">
          <button @click="editMessage(msg)" class="btn-edit">✏️ Editar</button>
          <button @click="deleteMessage(msg)" class="btn-delete">🗑️ Excluir</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue';
import { useStore } from 'vuex';

export default {
  name: 'ScheduledMessages',
  setup() {
    const store = useStore();
    const messages = ref([]);
    const loading = ref(false);
    const filters = ref({
      search: '',
      status: '',
      sortBy: 'date_asc'
    });

    const loadMessages = async () => {
      loading.value = true;
      try {
        const response = await store.dispatch('scheduledMessages/getAll', filters.value);
        messages.value = response.data;
      } catch (error) {
        console.error('Erro ao carregar mensagens:', error);
      } finally {
        loading.value = false;
      }
    };

    const formatDateTime = (date) => {
      return new Date(date).toLocaleString('pt-BR');
    };

    const statusLabel = (status) => {
      const labels = {
        pending: '⏳ Pendente',
        sent: '✅ Enviada',
        failed: '❌ Falhada'
      };
      return labels[status] || status;
    };

    const editMessage = (msg) => {
      // TODO: Implementar edição
      console.log('Editar:', msg);
    };

    const deleteMessage = async (msg) => {
      if (!confirm('Deseja excluir esta mensagem agendada?')) return;
      
      try {
        await store.dispatch('scheduledMessages/delete', msg.id);
        loadMessages();
      } catch (error) {
        console.error('Erro ao deletar:', error);
      }
    };

    const openScheduleModal = () => {
      // TODO: Abrir modal de agendamento
      console.log('Agendar nova mensagem');
    };

    onMounted(() => {
      loadMessages();
    });

    return {
      messages,
      loading,
      filters,
      loadMessages,
      formatDateTime,
      statusLabel,
      editMessage,
      deleteMessage,
      openScheduleModal
    };
  }
};
</script>

<style scoped>
.scheduled-messages-container {
  padding: 24px;
  max-width: 1400px;
  margin: 0 auto;
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.title {
  font-size: 24px;
  font-weight: 600;
  color: #1f2937;
}

.btn-new {
  padding: 10px 20px;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 14px;
}

.btn-new:hover {
  background: #2563eb;
}

.filters {
  display: flex;
  gap: 12px;
  margin-bottom: 24px;
}

.filter-input,
.filter-select {
  padding: 10px;
  border: 1px solid #d1d5db;
  border-radius: 6px;
  font-size: 14px;
}

.filter-input {
  flex: 1;
  max-width: 300px;
}

.messages-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 16px;
}

.message-card {
  background: white;
  border: 1px solid #e5e7eb;
  border-radius: 8px;
  padding: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.contact-info {
  display: flex;
  align-items: center;
  gap: 8px;
}

.avatar {
  width: 32px;
  height: 32px;
  border-radius: 50%;
}

.contact-name {
  font-weight: 500;
  color: #1f2937;
}

.status-badge {
  padding: 4px 8px;
  border-radius: 4px;
  font-size: 12px;
}

.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-sent {
  background: #d1fae5;
  color: #065f46;
}

.status-failed {
  background: #fee2e2;
  color: #991b1b;
}

.scheduled-time {
  font-size: 13px;
  color: #6b7280;
  margin-bottom: 12px;
}

.message-content {
  padding: 12px;
  background: #f9fafb;
  border-radius: 6px;
  margin-bottom: 12px;
  color: #374151;
  min-height: 60px;
}

.card-actions {
  display: flex;
  gap: 8px;
}

.btn-edit,
.btn-delete {
  padding: 6px 12px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  font-size: 13px;
}

.btn-edit {
  background: #3b82f6;
  color: white;
}

.btn-delete {
  background: #ef4444;
  color: white;
}

.loading {
  text-align: center;
  padding: 40px;
  color: #6b7280;
}
</style>
