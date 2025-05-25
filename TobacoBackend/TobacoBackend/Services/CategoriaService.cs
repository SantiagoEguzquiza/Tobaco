using AutoMapper;
using Microsoft.EntityFrameworkCore;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

public class CategoriaService : ICategoriaService
{
    private readonly ICategoriaRepository _repository;
    private readonly IMapper _mapper;

    public CategoriaService(ICategoriaRepository repository, IMapper mapper)
    {
        _repository = repository;
        _mapper = mapper;
    }

    public async Task<List<CategoriaDTO>> GetAllAsync()
    {
        var categorias = await _repository.GetAllAsync();
        return _mapper.Map<List<CategoriaDTO>>(categorias);
    }

    public async Task<CategoriaDTO?> GetByIdAsync(int id)
    {
        var categoria = await _repository.GetByIdAsync(id);
        return categoria == null ? null : _mapper.Map<CategoriaDTO>(categoria);
    }

    public async Task AddAsync(CategoriaDTO categoriaDto)
    {
        var categoria = _mapper.Map<Categoria>(categoriaDto);
        await _repository.AddAsync(categoria);
    }

    public async Task UpdateAsync(int id, CategoriaDTO categoriaDto)
    {
        var existing = await _repository.GetByIdAsync(id);
        if (existing != null)
        {
            existing.Nombre = categoriaDto.Nombre;
            await _repository.UpdateAsync(existing);
        }
    }

    public async Task DeleteAsync(int id)
    {
        try
        {
            await _repository.DeleteAsync(id);
        }
        catch (DbUpdateException)
        {
            throw new Exception("No se puede eliminar la categoría porque tiene productos asociados.");
        }
    }

}
