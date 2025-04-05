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
            var pedido = _mapper.Map<Pedido>(pedidoDto);
            pedido.Fecha = DateTime.Now;

            await _pedidoRepository.AddPedido(pedido);

            foreach (var productoDto in pedidoDto.PedidoProductos)
            {
                var producto = await _productoRepository.GetProductoById(productoDto.ProductoId);
                if (producto == null)
                {
                    throw new Exception($"Producto con ID {productoDto.ProductoId} no encontrado.");
                }


                var pedidoProducto = new PedidoProducto
                {
                    PedidoId = pedido.Id, 
                    ProductoId = producto.Id,
                    Cantidad = productoDto.Cantidad
                };

                await _pedidoRepository.AddOrUpdatePedidoProducto(pedidoProducto);
            }

            await _pedidoRepository.UpdatePedido(pedido); 
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
