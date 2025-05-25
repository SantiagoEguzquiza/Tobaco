using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TobacoBackend.Domain.Models
{
    public class Pedido
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        public int ClienteId { get; set; }

        [ForeignKey("ClienteId")]
        public Cliente Cliente { get; set; }

        public List<PedidoProducto> PedidoProductos { get; set; } = new List<PedidoProducto>();

        [Required]
        public decimal Total { get; set; }

        [Required]
        public DateTime Fecha { get; set; }
        public MetodoPagoEnum MetodoPago { get; set; }
    }
}
