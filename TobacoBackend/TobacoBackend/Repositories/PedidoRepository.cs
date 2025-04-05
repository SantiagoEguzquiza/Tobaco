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
            await _context.Pedidos.AddAsync(pedido);
            await _context.SaveChangesAsync();
        }

        public async Task AddPedidoProducto(PedidoProducto pedidoProducto)
        {
            await _context.PedidosProductos.AddAsync(pedidoProducto);
            await _context.SaveChangesAsync();
        }

        public async Task AddOrUpdatePedidoProducto(PedidoProducto pedidoProducto)
        {
            var pedidoProductoExistente = await _context.PedidosProductos
                .FirstOrDefaultAsync(pp => pp.PedidoId == pedidoProducto.PedidoId && pp.ProductoId == pedidoProducto.ProductoId);

            if (pedidoProductoExistente == null)
            {
                await _context.PedidosProductos.AddAsync(pedidoProducto);
            }
            else
            {
                pedidoProductoExistente.Cantidad = pedidoProducto.Cantidad;
            }

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
            if (pedido == null)
            {
                throw new Exception($"El pedido con id {id} no fue encontrado o no existe");
            }

            return pedido;
        }

        public async Task UpdatePedido(Pedido pedido)
        {
            var pedidoExistente = await _context.Pedidos.Include(p => p.PedidoProductos).FirstOrDefaultAsync(p => p.Id == pedido.Id);

            if (pedidoExistente == null)
            {
                throw new Exception("Pedido no encontrado");
            }

            _context.PedidosProductos.RemoveRange(pedidoExistente.PedidoProductos);

            pedidoExistente.PedidoProductos = pedido.PedidoProductos;

            decimal total = 0;

            foreach (var pedidoProducto in pedido.PedidoProductos)
            {
                var producto = await _context.Productos.FirstOrDefaultAsync(p => p.Id == pedidoProducto.ProductoId);
                if (producto != null)
                {
                    total += producto.Precio * pedidoProducto.Cantidad;
                }
            }

            pedidoExistente.Total = total;
            pedidoExistente.Fecha = pedido.Fecha;

            await _context.SaveChangesAsync();
        }
    }
}
