using TobacoBackend.Domain.Models;

namespace TobacoBackend.DTOs
{
    public class PedidoDTO
    {
        public int Id { get; set; }
        public int ClienteId { get; set; }
        public ClienteDTO Cliente { get; set; } 
        public List<PedidoProductoDTO> PedidoProductos { get; set; }
        public decimal Total { get; set; }
        public DateTime Fecha { get; set; }
        public MetodoPagoEnum MetodoPago { get; set; } 
    }
}
