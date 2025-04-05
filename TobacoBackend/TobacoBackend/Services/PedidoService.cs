using AutoMapper;
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
        private readonly IMapper _mapper;

        public PedidoService(IPedidoRepository pedidoRepository, IMapper mapper)
        {
            _pedidoRepository = pedidoRepository;
            _mapper = mapper;
        }

        public async Task AddPedido(PedidoDTO pedidoDto)
        {
            var pedido = _mapper.Map<Pedido>(pedidoDto);
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
