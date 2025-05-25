    using AutoMapper;
using TobacoBackend.Domain.IRepositories;
using TobacoBackend.Domain.IServices;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;
using TobacoBackend.Repositories;

namespace TobacoBackend.Services
{
    public class ProductoService : IProductoService
    {
        private readonly IProductoRepository _productoRepository;
        private readonly IMapper _mapper;

        public ProductoService(IProductoRepository productoRepository, IMapper mapper)
        {
            _productoRepository = productoRepository;
            _mapper = mapper;
        }

        public async Task AddProducto(ProductoDTO productoDto)
        {
            var producto = _mapper.Map<Producto>(productoDto);
            await _productoRepository.AddProducto(producto);
        }

        public async Task<bool> DeleteProducto(int id)
        {
            return await _productoRepository.DeleteProducto(id);
        }

        public async Task<List<ProductoDTO>> GetAllProductos()
        {
            var productos = await _productoRepository.GetAllProductos();
            return _mapper.Map<List<ProductoDTO>>(productos);
        }

        public async Task<ProductoDTO> GetProductoById(int id)
        {
            var producto = await _productoRepository.GetProductoById(id);
            return _mapper.Map<ProductoDTO>(producto);
        }

        public async Task UpdateProducto(int id, ProductoDTO productoDto)
        {
            var producto = _mapper.Map<Producto>(productoDto);
            producto.Id = id;
            await _productoRepository.UpdateProducto(producto);
        }
    }
}
