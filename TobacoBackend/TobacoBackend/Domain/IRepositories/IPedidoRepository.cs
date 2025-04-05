using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Domain.IRepositories
{
    public interface IPedidoRepository
    {
        Task<List<Pedido>> GetAllPedidos();
        Task<Pedido> GetPedidoById(int id);
        Task AddPedido(Pedido pedido);
        Task AddPedidoProducto(PedidoProducto pedidoProducto);
        Task AddOrUpdatePedidoProducto(PedidoProducto pedidoProducto);
        Task UpdatePedido(Pedido pedido);
        Task<bool> DeletePedido(int id);
    }
}
