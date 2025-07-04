using System;
using Microsoft.EntityFrameworkCore;
using TobacoBackend.Domain.Models;

public class AplicationDbContext : DbContext
{
    public DbSet<Cliente> Clientes { get; set; }
    public DbSet<Producto> Productos { get; set; }
    public DbSet<Pedido> Pedidos { get; set; }
    public DbSet<PedidoProducto> PedidosProductos { get; set; }
    public DbSet<Categoria> Categorias { get; set; }

    public AplicationDbContext(DbContextOptions<AplicationDbContext> options) : base(options)
    {
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);


        modelBuilder.Entity<Categoria>()
            .Property(c => c.Nombre)
            .IsRequired()
            .HasMaxLength(100);

        modelBuilder.Entity<Categoria>()
            .HasIndex(c => c.Nombre)
            .IsUnique();

        modelBuilder.Entity<PedidoProducto>()
            .HasKey(pp => new { pp.PedidoId, pp.ProductoId });

        modelBuilder.Entity<PedidoProducto>()
            .HasOne(pp => pp.Pedido)
            .WithMany(p => p.PedidoProductos)
            .HasForeignKey(pp => pp.PedidoId);

        modelBuilder.Entity<PedidoProducto>()
            .HasOne(pp => pp.Producto)
            .WithMany(p => p.PedidoProductos)
            .HasForeignKey(pp => pp.ProductoId);

        modelBuilder.Entity<Producto>()
            .Property(p => p.Precio)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Pedido>()
            .Property(p => p.Total)
            .HasPrecision(18, 2);

        modelBuilder.Entity<PedidoProducto>()
            .Property(p => p.Cantidad)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Producto>()
            .Property(p => p.Cantidad)
            .HasPrecision(18, 2);

        modelBuilder.Entity<Producto>()
            .HasOne(p => p.Categoria)
            .WithMany()
            .HasForeignKey(p => p.CategoriaId)
            .OnDelete(DeleteBehavior.Restrict);

    }

}
