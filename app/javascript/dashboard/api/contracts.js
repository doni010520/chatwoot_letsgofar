import ApiClient from './ApiClient';

class ContractsAPI extends ApiClient {
  constructor() {
    super('contracts', { accountScoped: true });
  }

  // Listar contratos com filtros
  list(params = {}) {
    return axios.get(this.url, { params });
  }

  // Obter contrato por ID
  get(id) {
    return axios.get(`${this.url}/${id}`);
  }

  // Criar contrato
  create(data) {
    return axios.post(this.url, { contract: data });
  }

  // Atualizar contrato
  update(id, data) {
    return axios.put(`${this.url}/${id}`, { contract: data });
  }

  // Excluir contrato
  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // Enviar para assinatura
  sendForSignature(id) {
    return axios.post(`${this.url}/${id}/send_for_signature`);
  }

  // Cancelar contrato
  cancel(id, reason = null) {
    return axios.post(`${this.url}/${id}/cancel`, { reason });
  }

  // Duplicar contrato
  duplicate(id) {
    return axios.post(`${this.url}/${id}/duplicate`);
  }

  // Reenviar para signatário
  resendToSigner(contractId, signerId) {
    return axios.post(`${this.url}/${contractId}/resend/${signerId}`);
  }

  // Download PDF
  downloadPdf(id) {
    return axios.get(`${this.url}/${id}/download_pdf`, { responseType: 'blob' });
  }

  // Contratos vencendo em 30 dias
  expiring() {
    return axios.get(`${this.url}/expiring`);
  }

  // Estatísticas
  stats() {
    return axios.get(`${this.url}/stats`);
  }
}

class ContractTemplatesAPI extends ApiClient {
  constructor() {
    super('contract_templates', { accountScoped: true });
  }

  // Listar templates
  list(params = {}) {
    return axios.get(this.url, { params });
  }

  // Obter template por ID
  get(id) {
    return axios.get(`${this.url}/${id}`);
  }

  // Criar template
  create(data) {
    return axios.post(this.url, { contract_template: data });
  }

  // Atualizar template
  update(id, data) {
    return axios.put(`${this.url}/${id}`, { contract_template: data });
  }

  // Excluir template
  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  // Preview do template com variáveis
  preview(id, variables = {}) {
    return axios.post(`${this.url}/${id}/preview`, { variables });
  }

  // Obter template padrão
  getDefault() {
    return axios.get(`${this.url}/default`);
  }
}

class PublicContractsAPI {
  constructor() {
    this.baseUrl = '/public/api/v1/contracts';
  }

  // Obter contrato por token
  get(token) {
    return axios.get(`${this.baseUrl}/${token}`);
  }

  // Assinar contrato
  sign(token, data) {
    return axios.post(`${this.baseUrl}/${token}/sign`, data);
  }

  // Recusar contrato
  refuse(token, reason = null) {
    return axios.post(`${this.baseUrl}/${token}/refuse`, { reason });
  }

  // Download do contrato
  download(token) {
    return axios.get(`${this.baseUrl}/${token}/download`, { responseType: 'blob' });
  }
}

export default new ContractsAPI();
export const ContractTemplates = new ContractTemplatesAPI();
export const PublicContracts = new PublicContractsAPI();
