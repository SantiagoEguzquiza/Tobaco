using Microsoft.AspNetCore.Mvc;
using TobacoBackend.Domain.IServices;
using TobacoBackend.DTOs;
using TobacoBackend.Services;

namespace TobacoBackend.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class ProductosController : ControllerBase
    {
        private readonly IProductoService _productoService;

        public ProductosController(IProductoService productoService)
        {
            _productoService = productoService;
        }


        [HttpGet]
        public async Task<ActionResult<List<ProductoDTO>>> GetAllProductos()
        {
            var productos = await _productoService.GetAllProductos();
            return Ok(productos);
        }


        [HttpGet("{id}")]
        public async Task<ActionResult<ProductoDTO>> GetProductoById(int id)
        {
            try
            {
                var producto = await _productoService.GetProductoById(id);
                return Ok(producto);
            }
            catch (Exception)
            {
                return NotFound(new { message = "No se encontraron productos que coincidan con el id." });
            }
        }



        [HttpPost]
        public async Task<ActionResult> AddProducto([FromBody] ProductoDTO productoDto)
        {
            try
            {
                if (productoDto == null)
                {
                    return BadRequest(new { message = "El producto no puede ser nulo." });
                }

                await _productoService.AddProducto(productoDto);

                return Ok(new { message = "Producto agregado exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest(new
                {
                    message = "Error al guardar el producto.",
                    error = ex.Message,
                    inner = ex.InnerException?.Message
                });
            }
        }




        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateProducto(int id, [FromBody] ProductoDTO productoDto)
        {
            if (productoDto == null || id != productoDto.Id)
            {
                return BadRequest(new { message = "ID del producto no coincide o el producto es nulo." });
            }

            try
            {
                await _productoService.UpdateProducto(id, productoDto);
                return Ok(new { message = "Producto actualizado exitosamente." });
            }
            catch (Exception)
            {
                return NotFound(new { message = "Producto no encontrado" });
            }
        }


        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteProducto(int id)
        {
            try
            {
                var deleteResult = await _productoService.DeleteProducto(id);
                if (deleteResult)
                {
                    return Ok(new { message = "Producto eliminado exitosamente." });
                }
                else
                {
                    return NotFound(new { message = "El producto no existe o no se pudo eliminar." });
                }
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Ocurrió un error al intentar eliminar el producto: {ex.Message}" });
            }
        }
    }
}
