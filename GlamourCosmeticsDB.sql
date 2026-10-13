/* GLAMOUR COSMETICS - SQL Server schema */
IF DB_ID(N'GlamourCosmeticsDB') IS NULL CREATE DATABASE GlamourCosmeticsDB;
GO
USE GlamourCosmeticsDB;
GO
CREATE TABLE dbo.Rol (
 RolId INT IDENTITY PRIMARY KEY,
 Nombre NVARCHAR(30) NOT NULL UNIQUE,
 Descripcion NVARCHAR(200) NULL
);
CREATE TABLE dbo.Usuario (
 UsuarioId INT IDENTITY PRIMARY KEY,
 RolId INT NOT NULL REFERENCES dbo.Rol(RolId),
 NombreCompleto NVARCHAR(120) NOT NULL,
 Correo NVARCHAR(254) NOT NULL UNIQUE,
 PasswordHash NVARCHAR(255) NOT NULL,
 Activo BIT NOT NULL DEFAULT 1,
 FechaCreacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.Categoria (
 CategoriaId INT IDENTITY PRIMARY KEY,
 Nombre NVARCHAR(80) NOT NULL UNIQUE,
 Descripcion NVARCHAR(250) NULL,
 Activa BIT NOT NULL DEFAULT 1
);
CREATE TABLE dbo.Producto (
 ProductoId INT IDENTITY PRIMARY KEY,
 CategoriaId INT NULL REFERENCES dbo.Categoria(CategoriaId),
 Codigo NVARCHAR(40) NOT NULL UNIQUE,
 Nombre NVARCHAR(120) NOT NULL,
 Descripcion NVARCHAR(1000) NULL,
 PrecioVenta DECIMAL(12,2) NOT NULL CHECK (PrecioVenta >= 0),
 Activo BIT NOT NULL DEFAULT 1,
 FechaCreacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FechaActualizacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.Inventario (
 ProductoId INT PRIMARY KEY REFERENCES dbo.Producto(ProductoId),
 Existencias INT NOT NULL DEFAULT 0 CHECK (Existencias >= 0),
 FechaActualizacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.Proveedor (
 ProveedorId INT IDENTITY PRIMARY KEY,
 Nombre NVARCHAR(150) NOT NULL,
 Documento NVARCHAR(40) NULL,
 Telefono NVARCHAR(30) NULL,
 Correo NVARCHAR(254) NULL,
 Direccion NVARCHAR(250) NULL,
 Activo BIT NOT NULL DEFAULT 1
);
CREATE TABLE dbo.CompraProveedor (
 CompraProveedorId INT IDENTITY PRIMARY KEY,
 ProveedorId INT NOT NULL REFERENCES dbo.Proveedor(ProveedorId),
 UsuarioId INT NOT NULL REFERENCES dbo.Usuario(UsuarioId),
 FechaCompra DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Estado NVARCHAR(20) NOT NULL DEFAULT N'BORRADOR'
   CHECK (Estado IN (N'BORRADOR',N'REGISTRADA',N'RECIBIDA',N'CANCELADA')),
 NumeroFactura NVARCHAR(60) NULL,
 Observaciones NVARCHAR(500) NULL,
 Total DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Total >= 0)
);
CREATE TABLE dbo.DetalleCompraProveedor (
 DetalleCompraProveedorId INT IDENTITY PRIMARY KEY,
 CompraProveedorId INT NOT NULL REFERENCES dbo.CompraProveedor(CompraProveedorId),
 ProductoId INT NOT NULL REFERENCES dbo.Producto(ProductoId),
 Cantidad INT NOT NULL CHECK (Cantidad > 0),
 CostoUnitario DECIMAL(12,2) NOT NULL CHECK (CostoUnitario >= 0),
 Subtotal AS CONVERT(DECIMAL(12,2),Cantidad*CostoUnitario) PERSISTED,
 UNIQUE (CompraProveedorId,ProductoId)
);
CREATE TABLE dbo.MovimientoInventario (
 MovimientoInventarioId BIGINT IDENTITY PRIMARY KEY,
 ProductoId INT NOT NULL REFERENCES dbo.Producto(ProductoId),
 UsuarioId INT NOT NULL REFERENCES dbo.Usuario(UsuarioId),
 Tipo NVARCHAR(15) NOT NULL CHECK (Tipo IN (N'ENTRADA',N'SALIDA',N'AJUSTE')),
 Cantidad INT NOT NULL CHECK (Cantidad > 0),
 ExistenciasAnteriores INT NOT NULL CHECK (ExistenciasAnteriores >= 0),
 ExistenciasNuevas INT NOT NULL CHECK (ExistenciasNuevas >= 0),
 Referencia NVARCHAR(100) NULL,
 Motivo NVARCHAR(250) NOT NULL,
 FechaMovimiento DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.Promocion (
 PromocionId INT IDENTITY PRIMARY KEY,
 Nombre NVARCHAR(120) NOT NULL,
 Descripcion NVARCHAR(500) NULL,
 TipoDescuento NVARCHAR(10) NOT NULL CHECK (TipoDescuento IN (N'PORCENTAJE',N'FIJO')),
 ValorDescuento DECIMAL(12,2) NOT NULL CHECK (ValorDescuento > 0),
 FechaInicio DATETIME2 NOT NULL,
 FechaFin DATETIME2 NOT NULL,
 Activa BIT NOT NULL DEFAULT 1,
 CHECK (FechaFin >= FechaInicio),
 CHECK (TipoDescuento <> N'PORCENTAJE' OR ValorDescuento <= 100)
);
CREATE TABLE dbo.ProductoPromocion (
 ProductoId INT NOT NULL REFERENCES dbo.Producto(ProductoId),
 PromocionId INT NOT NULL REFERENCES dbo.Promocion(PromocionId),
 PRIMARY KEY (ProductoId,PromocionId)
);
CREATE TABLE dbo.Carrito (
 CarritoId INT IDENTITY PRIMARY KEY,
 UsuarioId INT NOT NULL REFERENCES dbo.Usuario(UsuarioId),
 Estado NVARCHAR(15) NOT NULL DEFAULT N'ACTIVO'
   CHECK (Estado IN (N'ACTIVO',N'CONVERTIDO',N'ABANDONADO')),
 FechaCreacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FechaActualizacion DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
CREATE TABLE dbo.DetalleCarrito (
 DetalleCarritoId INT IDENTITY PRIMARY KEY,
 CarritoId INT NOT NULL REFERENCES dbo.Carrito(CarritoId),
 ProductoId INT NOT NULL REFERENCES dbo.Producto(ProductoId),
 Cantidad INT NOT NULL CHECK (Cantidad > 0),
 UNIQUE (CarritoId,ProductoId)
);
CREATE TABLE dbo.Pedido (
 PedidoId INT IDENTITY PRIMARY KEY,
 UsuarioClienteId INT NOT NULL REFERENCES dbo.Usuario(UsuarioId),
 FechaPedido DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Estado NVARCHAR(20) NOT NULL DEFAULT N'PENDIENTE'
   CHECK (Estado IN (N'PENDIENTE',N'CONFIRMADO',N'EN_PREPARACION',N'DESPACHADO',N'ENTREGADO',N'CANCELADO')),
 MetodoPago NVARCHAR(30) NOT NULL CHECK (MetodoPago IN (N'EFECTIVO',N'TRANSFERENCIA',N'OTRO')),
 Subtotal DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Subtotal >= 0),
 Descuento DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Descuento >= 0),
 Total DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (Total >= 0),
 Observaciones NVARCHAR(500) NULL
);
CREATE TABLE dbo.DetallePedido (
 DetallePedidoId INT IDENTITY PRIMARY KEY,
 PedidoId INT NOT NULL REFERENCES dbo.Pedido(PedidoId),
 ProductoId INT NOT NULL REFERENCES dbo.Producto(ProductoId),
 Cantidad INT NOT NULL CHECK (Cantidad > 0),
 PrecioUnitario DECIMAL(12,2) NOT NULL CHECK (PrecioUnitario >= 0),
 DescuentoUnitario DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (DescuentoUnitario >= 0),
 Subtotal AS CONVERT(DECIMAL(12,2),Cantidad*PrecioUnitario) PERSISTED,
 UNIQUE (PedidoId,ProductoId)
);
CREATE TABLE dbo.Pago (
 PagoId INT IDENTITY PRIMARY KEY,
 PedidoId INT NOT NULL REFERENCES dbo.Pedido(PedidoId),
 Metodo NVARCHAR(30) NOT NULL CHECK (Metodo IN (N'EFECTIVO',N'TRANSFERENCIA',N'OTRO')),
 Estado NVARCHAR(20) NOT NULL DEFAULT N'PENDIENTE'
   CHECK (Estado IN (N'PENDIENTE',N'VERIFICADO',N'RECHAZADO',N'REEMBOLSADO')),
 Importe DECIMAL(12,2) NOT NULL CHECK (Importe >= 0),
 ReferenciaExterna NVARCHAR(100) NULL,
 VerificadoPorUsuarioId INT NULL REFERENCES dbo.Usuario(UsuarioId),
 FechaRegistro DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 FechaVerificacion DATETIME2 NULL,
 Observaciones NVARCHAR(500) NULL
);
CREATE TABLE dbo.Venta (
 VentaId INT IDENTITY PRIMARY KEY,
 PedidoId INT NOT NULL UNIQUE REFERENCES dbo.Pedido(PedidoId),
 RegistradaPorUsuarioId INT NOT NULL REFERENCES dbo.Usuario(UsuarioId),
 FechaVenta DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
 Total DECIMAL(12,2) NOT NULL CHECK (Total >= 0),
 Observaciones NVARCHAR(500) NULL
);
CREATE INDEX IX_Producto_Nombre ON dbo.Producto(Nombre);
CREATE INDEX IX_Pedido_Cliente_Fecha ON dbo.Pedido(UsuarioClienteId,FechaPedido DESC);
CREATE INDEX IX_Pedido_Estado ON dbo.Pedido(Estado);
CREATE INDEX IX_MovimientoInventario_Producto_Fecha ON dbo.MovimientoInventario(ProductoId,FechaMovimiento DESC);
CREATE INDEX IX_CompraProveedor_Proveedor_Fecha ON dbo.CompraProveedor(ProveedorId,FechaCompra DESC);
INSERT INTO dbo.Rol (Nombre,Descripcion) VALUES
 (N'ADMINISTRADOR',N'Gestiona operaciones comerciales y administrativas.'),
 (N'CLIENTE',N'Consulta el catálogo y realiza sus propias compras.');
GO
