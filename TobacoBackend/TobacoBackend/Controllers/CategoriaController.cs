using Microsoft.AspNetCore.Mvc;
using TobacoBackend.Domain.IServices;
using TobacoBackend.DTOs;

namespace TobacoBackend.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class CategoriaController : ControllerBase
    {
        private readonly ICategoriaService _categoriaService;

        public CategoriaController(ICategoriaService categoriaService)
        {
            _categoriaService = categoriaService;
        }

        [HttpGet]
        public async Task<ActionResult<List<CategoriaDTO>>> GetAllCategorias()
        {
            var categorias = await _categoriaService.GetAllAsync();
            return Ok(categorias);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<CategoriaDTO>> GetCategoriaById(int id)
        {
            try
            {
                var categoria = await _categoriaService.GetByIdAsync(id);
                if (categoria == null)
                    return NotFound(new { message = "No se encontró la categoría con el ID proporcionado." });

                return Ok(categoria);
            }
            catch (Exception)
            {
                return BadRequest(new { message = "Ocurrió un error al buscar la categoría." });
            }
        }

        [HttpPost]
        public async Task<ActionResult> AddCategoria([FromBody] CategoriaDTO categoriaDto)
        {
            try
            {
                if (categoriaDto == null)
                    return BadRequest(new { message = "La categoría no puede ser nula." });

                await _categoriaService.AddAsync(categoriaDto);
                return Ok(new { message = "Categoría agregada exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error al agregar la categoría: {ex.Message}" });
            }
        }

        [HttpPut("{id}")]
        public async Task<ActionResult> UpdateCategoria(int id, [FromBody] CategoriaDTO categoriaDto)
        {
            if (categoriaDto == null || id != categoriaDto.Id)
                return BadRequest(new { message = "ID de la categoría no coincide o la categoría es nula." });

            try
            {
                await _categoriaService.UpdateAsync(id, categoriaDto);
                return Ok(new { message = "Categoría actualizada exitosamente." });
            }
            catch (Exception)
            {
                return NotFound(new { message = "Categoría no encontrada." });
            }
        }

        [HttpDelete("{id}")]
        public async Task<ActionResult> DeleteCategoria(int id)
        {
            try
            {
                await _categoriaService.DeleteAsync(id);
                return Ok(new { message = "Categoría eliminada exitosamente." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = $"Error al eliminar la categoría: {ex.Message}" });
            }
        }
    }
}
