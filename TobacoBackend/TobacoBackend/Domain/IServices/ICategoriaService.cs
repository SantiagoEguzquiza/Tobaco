using TobacoBackend.DTOs;

public interface ICategoriaService
{
    Task<List<CategoriaDTO>> GetAllAsync();
    Task<CategoriaDTO?> GetByIdAsync(int id);
    Task AddAsync(CategoriaDTO categoriaDto);
    Task UpdateAsync(int id, CategoriaDTO categoriaDto);
    Task DeleteAsync(int id);
}
