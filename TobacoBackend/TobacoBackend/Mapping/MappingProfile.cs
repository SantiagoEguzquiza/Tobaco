using AutoMapper;
using TobacoBackend.Domain.Models;
using TobacoBackend.DTOs;

namespace TobacoBackend.Mapping
{
    public class MappingProfile : Profile
    {
        public MappingProfile()
        {
            CreateMap<Cliente, ClienteDTO>().ReverseMap();
            CreateMap<Pedido, PedidoDTO>().ReverseMap();
            CreateMap<PedidoProducto, PedidoProductoDTO>().ReverseMap();
            CreateMap<Categoria, CategoriaDTO>().ReverseMap();

            // Mapeo personalizado para Producto
            CreateMap<ProductoDTO, Producto>()
                .ForMember(dest => dest.Categoria, opt => opt.Ignore())
                .ForMember(dest => dest.CategoriaId, opt => opt.MapFrom(src => src.CategoriaId));

            CreateMap<Producto, ProductoDTO>()
                .ForMember(dest => dest.CategoriaId, opt => opt.MapFrom(src => src.Categoria.Id))
                .ForMember(dest => dest.CategoriaNombre, opt => opt.MapFrom(src => src.Categoria.Nombre));
        }
    }
}
