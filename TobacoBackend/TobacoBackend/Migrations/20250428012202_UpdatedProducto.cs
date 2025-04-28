using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace TobacoBackend.Migrations
{
    /// <inheritdoc />
    public partial class UpdatedProducto : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "half",
                table: "Clientes");

            migrationBuilder.AddColumn<bool>(
                name: "Half",
                table: "Productos",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Half",
                table: "Productos");

            migrationBuilder.AddColumn<bool>(
                name: "half",
                table: "Clientes",
                type: "bit",
                nullable: false,
                defaultValue: false);
        }
    }
}
