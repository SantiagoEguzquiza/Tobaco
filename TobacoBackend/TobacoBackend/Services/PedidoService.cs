using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TobacoBackend.Domain.IRepositories;
using TobacoBackend.Domain.IServices;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;
using TobacoBackend.Repositories;

namespace TobacoBackend.Services
{
    public class PedidoService : IPedidoService
    {
        private readonly IPedidoRepository _pedidoRepository;
        private readonly IProductoRepository _productoRepository;
        private readonly IMapper _mapper;

        public PedidoService(IPedidoRepository pedidoRepository, IMapper mapper, IProductoRepository productoRepository)
        {
            _pedidoRepository = pedidoRepository;
            _mapper = mapper;
            _productoRepository = productoRepository;
        }

        public async Task AddPedido(PedidoDTO pedidoDto)
        {
            var pedido = new Pedido
            {
                ClienteId = pedidoDto.ClienteId,
                Fecha = DateTime.Now,
                PedidoProductos = new List<PedidoProducto>()
            };

            decimal total = 0;

            foreach (var productoDto in pedidoDto.PedidoProductos)
            {
                var producto = await _productoRepository.GetProductoById(productoDto.ProductoId);
                if (producto == null)
                {
                    throw new Exception($"Producto con ID {productoDto.ProductoId} no encontrado.");
                }

                var pedidoProducto = new PedidoProducto
                {
                    ProductoId = producto.Id,
                    Cantidad = productoDto.Cantidad
                };

                total += producto.Precio * productoDto.Cantidad;

                pedido.PedidoProductos.Add(pedidoProducto);
            }

            pedido.Total = total;

            await _pedidoRepository.AddPedido(pedido);
        }




        public async Task<bool> DeletePedido(int id)
        {
            return await _pedidoRepository.DeletePedido(id);
        }

        public async Task<List<PedidoDTO>> GetAllPedidos()
        {
            var pedido = await _pedidoRepository.GetAllPedidos();
            return _mapper.Map<List<PedidoDTO>>(pedido);
        }

        public async Task<PedidoDTO> GetPedidoById(int id)
        {
            var pedido = await _pedidoRepository.GetPedidoById(id);
            return _mapper.Map<PedidoDTO>(pedido);
        }

        public async Task UpdatePedido(int id, PedidoDTO pedidoDto)
        {
            var pedido = _mapper.Map<Pedido>(pedidoDto);
            pedido.Id = id;
            await _pedidoRepository.UpdatePedido(pedido);
        }
    }
}
