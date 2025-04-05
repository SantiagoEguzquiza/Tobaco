using Microsoft.EntityFrameworkCore;
using TobacoBackend.Domain.IRepositories;
using TobacoBackend.Domain.Models;

namespace TobacoBackend.Repositories
{
    public class PedidoRepository : IPedidoRepository
    {
        private readonly AplicationDbContext _context;

        public PedidoRepository(AplicationDbContext context)
        {
            this._context = context;
        }

        public async Task AddPedido(Pedido pedido)
        {
            _context.Pedidos.Add(pedido);
            await _context.SaveChangesAsync();
        }

        public async Task<bool> DeletePedido(int id)
        {
            var pedido = await _context.Pedidos.FirstOrDefaultAsync(c => c.Id == id);

            if (pedido != null)
            {
                _context.Pedidos.Remove(pedido);
                await _context.SaveChangesAsync();
                return true;
            }

            return false;
        }

        public async Task<List<Pedido>> GetAllPedidos()
        {
            return await _context.Pedidos.ToListAsync();
        }

        public async Task<Pedido> GetPedidoById(int id)
        {
            var pedido = await _context.Pedidos.FirstOrDefaultAsync(c => c.Id == id);
            if(pedido == null)
            {
                throw new Exception($"El pedido con id {id} no fue encontrado o no existe");
            }

            return pedido;
        }

        public async Task UpdatePedido(Pedido pedido)
        {
            _context.Pedidos.Update(pedido);
            await _context.SaveChangesAsync();
        }
    }
}
