// Helpers para datas de contrato.
//
// Bug raiz que estes helpers resolvem:
// O input <input type="date"> grava no v-model como "YYYY-MM-DD" (apenas
// a data, sem hora ou timezone). Quando passamos isso para `new Date(str)`,
// o JavaScript interpreta como UTC meia-noite. Ao chamar
// `.toLocaleDateString('pt-BR')` no Brasil (UTC-3), o resultado fica um
// dia ANTES do que foi escolhido (ex: 2026-06-06 vira 05/06/2026).
//
// A solução é parsear "YYYY-MM-DD" como data LOCAL (sem timezone)
// e ignorar conversões UTC.

/**
 * Converte uma string ou Date em "DD/MM/YYYY" sem deslocamento de timezone.
 * - Aceita "YYYY-MM-DD" (formato do input date) → trata como data local
 * - Aceita "YYYY-MM-DDTHH:MM:SS..." (ISO com hora) → mantém comportamento padrão
 * - Aceita Date → mantém comportamento padrão
 * - Vazio/null/undefined → retorna fallback
 */
export const formatContractDate = (value, fallback = '-') => {
  if (!value) return fallback;

  // Caso 1: string no formato exato YYYY-MM-DD (sem hora) — formata sem usar Date()
  if (typeof value === 'string') {
    const dateOnly = value.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (dateOnly) {
      const [, year, month, day] = dateOnly;
      return `${day}/${month}/${year}`;
    }
  }

  // Demais casos: usa Date normal (datetime com timezone já correto)
  try {
    const d = value instanceof Date ? value : new Date(value);
    if (Number.isNaN(d.getTime())) return fallback;
    return d.toLocaleDateString('pt-BR');
  } catch {
    return fallback;
  }
};

/**
 * Data de "hoje" no formato DD/MM/YYYY no fuso local do navegador.
 * Usado para `contract_date` em variáveis.
 */
export const todayBR = () => {
  const d = new Date();
  const dd = String(d.getDate()).padStart(2, '0');
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const yyyy = d.getFullYear();
  return `${dd}/${mm}/${yyyy}`;
};
