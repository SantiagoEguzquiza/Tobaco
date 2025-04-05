using Microsoft.AspNetCore.Mvc;
using TobacoBackend.Domain.IServices;
using TobacoBackend.DTOs;
using TobacoBackend.Services;

namespace TobacoBackend.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class PedidosController : ControllerBase
    {
        private readonly IPedidoService _pedidosService;

        public PedidosController(IPedidoService pedidosService)
        {
            _pedidosService = pedidosService;
        }


        [HttpGet]
        public async Task<ActionResult<List<PedidoDTO>>> GetAllPedidos()
        {
            var pedidos = await _pedidosService.GetAllPedidos();
            return Ok(pedidos);
        }



        [HttpGet("{id}")]
        public async Task<ActionResult<PedidoDTO>> GetPedidoById(int id)
        {
            try
            {
                var pedido = await _pedidosService.GetPedidoById(id);
                return Ok(pedido);
            }
            catch (Exception)
            {
                return NotFound(new { message = "No se encontraron pedidos que coincidan con el id." });
            }
        }



        [HttpPost]
        public async Task<ActionResult> AddPedido([FromBody] PedidoDTO pedidoDto)
        {
            try
            {
                if (pedidoDto == null)
                {
                    return BadRequest(new { message = "El pedido no puede ser nulo." });
                }

                await _pedidosService.AddPedido(pedidoDto);

                return Ok(new { message = "Pedido agregado exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest(ex.Message);
            }
        }




        [HttpPut("{id}")]
        public async Task<ActionResult> UpdatePedido(int id, [FromBody] PedidoDTO pedidoDto)
        {
            if (pedidoDto == null || id != pedidoDto.Id)
            {
                return BadRequest(new { message = "ID del pedido no coincide o el pedido es nulo." });
            }

            try
            {
                await _pedidosService.UpdatePedido(id, pedidoDto);
                return Ok(new { message = "Pedido actualizado exitosamente." });
            }
            catch (Exception)
            {
                return NotFound(new { message = "Pedido no encontrado" });
            }
        }



        [HttpDelete("{id}")]
        public async Task<ActionResult> DeletePedido(int id)
        {
            try
            {
                var deleteResult = await _pedidosService.DeletePedido(id);
                if (deleteResult)
                {
                    return Ok(new { message = "Pedido eliminado exitosamente." });
                }
                else
                {
                    return NotFound(new { message = "El pedido no existe o no se pudo eliminar." });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Ocurrió un error al intentar eliminar el pedido: {ex.Message}" });
            }
        }
    }
}
