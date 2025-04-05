using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Domain.IServices
{
    public interface IPedidoService
    {
        Task<List<PedidoDTO>> GetAllPedidos();
        Task<PedidoDTO> GetPedidoById(int id);
        Task AddPedido(PedidoDTO pedidoDto);
        Task UpdatePedido(int id, PedidoDTO pedidoDto);
        Task<bool> DeletePedido(int id);
    }
}
