using System.Diagnostics.Contracts;
using Microsoft.AspNetCore.Mvc;
using TobacoBackend.Domain.IServices;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ClientesController : ControllerBase
    {
        private readonly IClienteService _clienteService;

        public ClientesController(IClienteService clienteService)
        {
            _clienteService = clienteService;
        }

        
        [HttpGet]
        public async Task<ActionResult<List<ClienteDTO>>> GetAllClientes()
        {
            var clientes = await _clienteService.GetAllClientes();
            return Ok(clientes);
        }

        
        [HttpGet("{id}")]
        public async Task<ActionResult<ClienteDTO>> GetClienteById(int id)
        {
            try
            {
                var cliente = await _clienteService.GetClienteById(id);
                return Ok(cliente);
            }
            catch (Exception)
            {
                return NotFound(new { message = "No se encontraron clientes que coincidan con el id." });
            }
        }

       
        [HttpPost]
        public async Task<ActionResult> AddCliente([FromBody] ClienteDTO clienteDto)
        {
            try
            {
                if (clienteDto == null)
                {
                    return BadRequest(new { message = "El cliente no puede ser nulo." });
                }

                await _clienteService.AddCliente(clienteDto);

                return Ok(new { message = "Cliente agregado exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateCliente(int id, [FromBody] ClienteDTO clienteDto)
        {
            if (clienteDto == null || id != clienteDto.Id)
            {
                return BadRequest(new { message = "ID del cliente no coincide o el cliente es nulo." });
            }

            try
            {
                await _clienteService.UpdateCliente(id, clienteDto);
                return Ok(new { message = "Cliente actualizado exitosamente." });
            }
            catch (Exception)
            {
                return NotFound(new { message = "Cliente no encontrado" });
            }
        }


        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteCliente(int id)
        {
            try
            {
                var deleteResult = await _clienteService.DeleteCliente(id);
                if (deleteResult)
                {
                    return Ok(new { message = "Cliente eliminado exitosamente." });
                }
                else
                {
                    return NotFound(new { message = "El cliente no existe o no se pudo eliminar." });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Ocurrió un error al intentar eliminar el cliente: {ex.Message}" });
            }
        }

        // GET: api/clientes/buscar?query=juan
        [HttpGet("buscar")]
        public async Task<IActionResult> BuscarClientes([FromQuery] string query)
        {
            if (string.IsNullOrWhiteSpace(query))
                return BadRequest("El parámetro de búsqueda no puede estar vacío.");

            var clientes = await _clienteService.BuscarClientesAsync(query);
            return Ok(clientes);
        }

        [HttpGet("con-deuda")]
        public async Task<ActionResult<List<ClienteDTO>>> GetClientesConDeuda()
        {
            var clientes = await _clienteService.GetClientesConDeuda();
            return Ok(clientes);
        }
    }
}
