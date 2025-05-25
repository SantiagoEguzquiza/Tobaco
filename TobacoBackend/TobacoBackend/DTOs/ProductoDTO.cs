using TobacoBackend.Domain.Models;

namespace TobacoBackend.DTOs
{
    public class ProductoDTO
    {
        public int Id { get; set; }
        public string Nombre { get; set; }
        public decimal Cantidad { get; set; }
        public decimal Precio { get; set; }
        public int CategoriaId { get; set; }         
        public string CategoriaNombre { get; set; }   
        public bool Half { get; set; } = false;
    }
}
