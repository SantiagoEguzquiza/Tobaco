using System.Diagnostics.Contracts;
using Microsoft.EntityFrameworkCore;
using TobacoBackend.Domain.IRepositories;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Repositories
{
    public class ClienteRepository : IClienteRepository
    {
        private readonly AplicationDbContext _context;

        public ClienteRepository(AplicationDbContext context)
        {
            this._context = context;
        }

        public async Task AddCliente(Cliente cliente)
        {
            _context.Clientes.Add(cliente);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> DeleteCliente(int id)
        {
            var cliente = await _context.Clientes.Where(c => c.Id == id).FirstOrDefaultAsync();

            if (cliente != null)
            {
                _context.Clientes.Remove(cliente);
                await _context.SaveChangesAsync();
                return true;
            }

            return false;

        }

        public async Task UpdateCliente(Cliente cliente)
        {
            _context.Clientes.Update(cliente);
            await _context.SaveChangesAsync();
        }

        public async Task<Cliente> GetClienteById(int id)
        {
            var cliente = await _context.Clientes.FirstOrDefaultAsync(c => c.Id ==id);
            if (cliente == null)
            {
                throw new Exception($"El cliente con id {id} no fue encontrado o no existe");
            }

            return cliente;
        }

        public async Task<List<Cliente>> GetAllClientes()
        {
            return await _context.Clientes.ToListAsync();
        }

        public async Task<IEnumerable<Cliente>> BuscarClientesAsync(string query)
        {
            return await _context.Clientes
                .Where(c => c.Nombre.Contains(query))
                .ToListAsync();
        }

        public async Task<List<Cliente>> GetClientesConDeuda()
        {
            var clientes = await _context.Clientes.ToListAsync(); 
            var clientesConDeuda = clientes.Where(c => c.DeudaDecimal > 0).ToList(); 
            return clientesConDeuda;
        }
    }
}
