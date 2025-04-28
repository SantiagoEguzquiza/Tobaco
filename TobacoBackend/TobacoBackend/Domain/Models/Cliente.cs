using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace TobacoBackend.Domain.Models
{
    public class Cliente
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Required]
        public string Nombre { get; set; }

        [Required]
        public string Direccion { get; set; }

        [Required]
        public string Telefono { get; set; }

        public string Deuda { get; set; }

        public List<Pedido> Pedidos { get; set; } = new List<Pedido>();

        [NotMapped]
        public decimal DeudaDecimal => decimal.TryParse(Deuda, out var value) ? value : 0;
    }
}
