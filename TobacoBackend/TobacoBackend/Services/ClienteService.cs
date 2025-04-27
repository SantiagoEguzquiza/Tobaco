using AutoMapper;
using TobacoBackend.Domain.IRepositories;
using TobacoBackend.Domain.IServices;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Services
{
    public class ClienteService : IClienteService
    {
        private readonly IClienteRepository _clienteRepository;
        private readonly IMapper _mapper;

        public ClienteService(IClienteRepository clienteRepository, IMapper mapper)
        {
            _clienteRepository = clienteRepository;
            _mapper = mapper;
        }
        public async Task AddCliente(ClienteDTO clienteDto)
        {
            var cliente = _mapper.Map<Cliente>(clienteDto);
            await _clienteRepository.AddCliente(cliente);
        }

        public async Task<bool> DeleteCliente(int id)
        {
            return await _clienteRepository.DeleteCliente(id);
        }

        public async Task<List<ClienteDTO>> GetAllClientes()
        {
            var clientes = await _clienteRepository.GetAllClientes();
            return _mapper.Map<List<ClienteDTO>>(clientes);
        }

        public async Task<ClienteDTO> GetClienteById(int id)
        {
            var cliente = await _clienteRepository.GetClienteById(id);
            return _mapper.Map<ClienteDTO>(cliente);
        }

        public async Task UpdateCliente(int id, ClienteDTO clienteDto)
        {
            var cliente = _mapper.Map<Cliente>(clienteDto);
            cliente.Id = id;
            await _clienteRepository.UpdateCliente(cliente);
        }

        public async Task<IEnumerable<ClienteDTO>> BuscarClientesAsync(string query)
        {
            var clientes = await _clienteRepository.BuscarClientesAsync(query);
            return _mapper.Map<IEnumerable<ClienteDTO>>(clientes);
        }

        public async Task<List<ClienteDTO>> GetClientesConDeuda()
        {
            var clientes = await _clienteRepository.GetClientesConDeuda();
            return _mapper.Map<List<ClienteDTO>>(clientes);
        }
    }
}
