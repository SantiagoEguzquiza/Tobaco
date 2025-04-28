using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Domain.IServices
{
    public interface IClienteService
    {
        Task<List<ClienteDTO>> GetAllClientes();
        Task<ClienteDTO> GetClienteById(int id);
        Task AddCliente(ClienteDTO cliente);
        Task UpdateCliente(int id, ClienteDTO cliente);
        Task<bool> DeleteCliente(int id);
        Task<IEnumerable<ClienteDTO>> BuscarClientesAsync(string query);
        Task<List<ClienteDTO>> GetClientesConDeuda();
    }
}
