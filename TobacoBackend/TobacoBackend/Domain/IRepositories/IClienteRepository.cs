using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Domain.IRepositories
{
    public interface IClienteRepository
    {
        Task<List<Cliente>> GetAllClientes();
        Task<Cliente> GetClienteById(int id);
        Task AddCliente(Cliente cliente);
        Task UpdateCliente(Cliente cliente);
        Task<bool> DeleteCliente(int id);
        Task<IEnumerable<Cliente>> BuscarClientesAsync(string query);
        Task<List<Cliente>> GetClientesConDeuda();
    }
}
