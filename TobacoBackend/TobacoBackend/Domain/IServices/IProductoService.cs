using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Domain.IServices
{
    public interface IProductoService
    {
        Task<List<ProductoDTO>> GetAllProductos();
        Task<ProductoDTO> GetProductoById(int id);
        Task AddProducto(ProductoDTO productoDto);
        Task UpdateProducto(int id, ProductoDTO productoDto);
        Task<bool> DeleteProducto(int id);
    }
}
