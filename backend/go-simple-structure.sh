#!/bin/bash

# generate-simple-structure.sh
# Script untuk generate struktur folder Clean Architecture versi Simple dengan Fiber
# Usage: bash generate-simple-structure.sh [project-name]

PROJECT_NAME=${1:-"my-go-project"}

echo "🚀 Generating Clean Architecture Simple structure (Fiber) for: $PROJECT_NAME"
echo "================================================"

# Create main project directory
mkdir -p $PROJECT_NAME
cd $PROJECT_NAME

# Create folder structure
echo "📁 Creating folder structure..."

folders=(
    "cmd"
    "config"
    "models"
    "handlers"
    "repositories"
    "middlewares"
    "utils"
    "routes"
)

for folder in "${folders[@]}"; do
    mkdir -p $folder
    echo "✅ Created: $folder/"
done

# ========================================
# CMD Directory Documentation
# ========================================
cat > cmd/README.md << 'EOF'
# CMD Directory

## 📖 Filosofi
CMD adalah singkatan dari **Command**. Folder ini berisi entry point aplikasi - tempat dimana program dimulai. Filosofinya adalah memisahkan kode startup aplikasi dari business logic, sehingga mudah untuk membuat multiple entry points jika diperlukan (misalnya: API server, CLI tools, workers).

## 🎯 Definisi
Directory yang berisi file `main.go` sebagai entry point aplikasi. Di sinilah semua komponen aplikasi (database, repositories, handlers, routes) diinisialisasi dan dihubungkan.

## 💡 Tanggung Jawab
- Inisialisasi konfigurasi
- Setup database connection
- Dependency injection (manual)
- Setup Fiber app
- Graceful shutdown handling

## 📝 Contoh Struktur
```
cmd/
├── main.go           # Entry point utama
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode
```go
package main

import (
    "log"
    "os"
    "os/signal"
    "myproject/config"
    "myproject/handlers"
    "myproject/repositories"
    "myproject/routes"
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/logger"
    "github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
    // 1. Load configuration
    cfg := config.LoadConfig()

    // 2. Connect to database
    db := config.ConnectDB(cfg)

    // 3. Initialize repositories
    userRepo := repositories.NewUserRepository(db)
    productRepo := repositories.NewProductRepository(db)

    // 4. Initialize handlers
    userHandler := handlers.NewUserHandler(userRepo)
    productHandler := handlers.NewProductHandler(productRepo)

    // 5. Create Fiber app
    app := fiber.New(fiber.Config{
        ErrorHandler: customErrorHandler,
        AppName:      "My API v1.0.0",
    })

    // 6. Global middlewares
    app.Use(recover.New())
    app.Use(logger.New())

    // 7. Setup routes
    routes.SetupRoutes(app, userHandler, productHandler)

    // 8. Graceful shutdown
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    go func() {
        <-c
        log.Println("🛑 Gracefully shutting down...")
        app.Shutdown()
    }()

    // 9. Start server
    log.Printf("🚀 Server running on port %s", cfg.Port)
    if err := app.Listen(":" + cfg.Port); err != nil {
        log.Fatal("❌ Failed to start server:", err)
    }
}

func customErrorHandler(c *fiber.Ctx, err error) error {
    code := fiber.StatusInternalServerError

    if e, ok := err.(*fiber.Error); ok {
        code = e.Code
    }

    return c.Status(code).JSON(fiber.Map{
        "status":  "error",
        "message": err.Error(),
    })
}
```

## ⚠️ Best Practices
- ✅ Keep main.go thin - hanya untuk wiring dependencies
- ✅ Jangan taruh business logic di sini
- ✅ Gunakan dependency injection pattern
- ✅ Handle graceful shutdown untuk production
- ✅ Setup custom error handler
- ❌ Jangan hardcode values - gunakan config

## 🎓 Tips Fiber
- Fiber lebih cepat dari Gin (inspired by Express.js)
- Fiber menggunakan fasthttp (bukan net/http)
- Error handling lebih simple dengan return values
- Built-in middleware sangat lengkap
EOF

# ========================================
# CONFIG Directory Documentation
# ========================================
cat > config/README.md << 'EOF'
# CONFIG Directory

## 📖 Filosofi
**"Configuration should be external, not hardcoded"**. Filosofi dari folder config adalah memisahkan semua konfigurasi aplikasi ke satu tempat yang mudah dikelola. Ini mengikuti prinsip 12-Factor App dimana config harus disimpan di environment variables.

## 🎯 Definisi
Directory yang berisi file-file untuk mengelola konfigurasi aplikasi seperti database connection, API keys, server port, dan pengaturan lainnya. Biasanya menggunakan environment variables atau file konfigurasi (.env, .yaml, .json).

## 💡 Tanggung Jawab
- Load environment variables
- Validasi konfigurasi
- Setup database connection
- Manage external service credentials
- Environment-specific settings (dev, staging, prod)

## 📝 Contoh Struktur
```
config/
├── config.go         # Load & validate config
├── database.go       # Database connection setup
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode

### config.go
```go
package config

import (
    "log"
    "os"
    "github.com/joho/godotenv"
)

type Config struct {
    // Server
    Port        string
    Environment string

    // Database
    DBHost     string
    DBPort     string
    DBUser     string
    DBPassword string
    DBName     string

    // JWT
    JWTSecret string

    // External APIs
    PaymentAPIKey string
}

func LoadConfig() *Config {
    // Load .env file
    if err := godotenv.Load(); err != nil {
        log.Println("⚠️  No .env file found, using system environment variables")
    }

    config := &Config{
        Port:          getEnv("PORT", "3000"),
        Environment:   getEnv("ENVIRONMENT", "development"),
        DBHost:        getEnv("DB_HOST", "localhost"),
        DBPort:        getEnv("DB_PORT", "5432"),
        DBUser:        getEnv("DB_USER", "postgres"),
        DBPassword:    getEnv("DB_PASSWORD", ""),
        DBName:        getEnv("DB_NAME", "myapp"),
        JWTSecret:     getEnv("JWT_SECRET", "your-secret-key"),
        PaymentAPIKey: getEnv("PAYMENT_API_KEY", ""),
    }

    // Validate critical configs
    if config.DBPassword == "" {
        log.Fatal("❌ DB_PASSWORD is required")
    }

    if config.JWTSecret == "your-secret-key" {
        log.Println("⚠️  WARNING: Using default JWT secret. Change this in production!")
    }

    return config
}

func getEnv(key, defaultValue string) string {
    if value := os.Getenv(key); value != "" {
        return value
    }
    return defaultValue
}
```

### database.go
```go
package config

import (
    "fmt"
    "log"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
    "gorm.io/gorm/logger"
)

func ConnectDB(cfg *Config) *gorm.DB {
    dsn := fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
        cfg.DBHost, cfg.DBPort, cfg.DBUser, cfg.DBPassword, cfg.DBName,
    )

    // Configure GORM logger
    logLevel := logger.Silent
    if cfg.Environment == "development" {
        logLevel = logger.Info
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{
        Logger: logger.Default.LogMode(logLevel),
    })

    if err != nil {
        log.Fatal("❌ Failed to connect to database:", err)
    }

    log.Println("✅ Database connected successfully")
    return db
}
```

## ⚠️ Best Practices
- ✅ Gunakan environment variables untuk sensitive data
- ✅ Provide default values untuk non-critical configs
- ✅ Validasi konfigurasi saat startup
- ✅ Jangan commit file .env ke git
- ✅ Buat .env.example sebagai template
- ❌ Jangan hardcode credentials di code

## 🎓 Tips
- Gunakan library seperti `godotenv` untuk load .env files
- Untuk production, gunakan secret management (AWS Secrets Manager, Vault)
- Buat config berbeda per environment (dev, staging, prod)
EOF

# ========================================
# MODELS Directory Documentation
# ========================================
cat > models/README.md << 'EOF'
# MODELS Directory

## 📖 Filosofi
**"Models are the source of truth about your data"**. Models merepresentasikan struktur data aplikasi dan business entities. Filosofinya adalah memiliki single source of truth untuk struktur data yang digunakan di seluruh aplikasi.

## 🎯 Definisi
Directory yang berisi definisi struct Go yang merepresentasikan tabel database dan business entities. Menggunakan GORM tags untuk mapping ke database dan JSON tags untuk API responses.

## 💡 Tanggung Jawab
- Definisi struktur data (entities)
- Database schema mapping (via GORM tags)
- JSON serialization rules
- Data validation rules
- Business rules di level entity
- Relationships antar entities

## 📝 Contoh Struktur
```
models/
├── user.go           # User entity
├── product.go        # Product entity
├── order.go          # Order entity
├── common.go         # Shared models (timestamps, pagination)
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode

### user.go
```go
package models

import (
    "time"
    "github.com/google/uuid"
    "gorm.io/gorm"
)

type User struct {
    ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
    Email     string    `gorm:"uniqueIndex;not null" json:"email"`
    Name      string    `gorm:"not null" json:"name"`
    Password  string    `gorm:"not null" json:"-"` // Hidden from JSON
    Role      string    `gorm:"type:varchar(20);default:'user'" json:"role"`
    IsActive  bool      `gorm:"default:true" json:"is_active"`
    CreatedAt time.Time `gorm:"autoCreateTime" json:"created_at"`
    UpdatedAt time.Time `gorm:"autoUpdateTime" json:"updated_at"`

    // Relationships
    Orders []Order `gorm:"foreignKey:UserID" json:"orders,omitempty"`
}

// BeforeCreate - GORM hook
func (u *User) BeforeCreate(tx *gorm.DB) error {
    u.ID = uuid.New()
    return nil
}

// TableName - Custom table name
func (User) TableName() string {
    return "users"
}

// Business logic methods
func (u *User) IsAdmin() bool {
    return u.Role == "admin"
}

func (u *User) CanDelete() bool {
    return !u.IsAdmin() // Admin tidak bisa dihapus
}
```

### product.go
```go
package models

import (
    "errors"
    "time"
    "github.com/google/uuid"
)

type Product struct {
    ID          uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
    Name        string    `gorm:"not null" json:"name"`
    Description string    `gorm:"type:text" json:"description"`
    Price       float64   `gorm:"type:decimal(10,2);not null" json:"price"`
    Stock       int       `gorm:"default:0" json:"stock"`
    CategoryID  uuid.UUID `gorm:"type:uuid" json:"category_id"`
    IsActive    bool      `gorm:"default:true" json:"is_active"`
    CreatedAt   time.Time `gorm:"autoCreateTime" json:"created_at"`
    UpdatedAt   time.Time `gorm:"autoUpdateTime" json:"updated_at"`

    // Relationships
    Category Category `gorm:"foreignKey:CategoryID" json:"category,omitempty"`
}

// Business methods
func (p *Product) IsAvailable() bool {
    return p.IsActive && p.Stock > 0
}

func (p *Product) ReduceStock(quantity int) error {
    if p.Stock < quantity {
        return errors.New("insufficient stock")
    }
    p.Stock -= quantity
    return nil
}
```

### order.go
```go
package models

import (
    "time"
    "github.com/google/uuid"
)

type OrderStatus string

const (
    OrderPending   OrderStatus = "pending"
    OrderPaid      OrderStatus = "paid"
    OrderShipped   OrderStatus = "shipped"
    OrderDelivered OrderStatus = "delivered"
    OrderCancelled OrderStatus = "cancelled"
)

type Order struct {
    ID         uuid.UUID   `gorm:"type:uuid;primaryKey" json:"id"`
    UserID     uuid.UUID   `gorm:"type:uuid;not null" json:"user_id"`
    TotalPrice float64     `gorm:"type:decimal(10,2);not null" json:"total_price"`
    Status     OrderStatus `gorm:"type:varchar(20);default:'pending'" json:"status"`
    CreatedAt  time.Time   `gorm:"autoCreateTime" json:"created_at"`
    UpdatedAt  time.Time   `gorm:"autoUpdateTime" json:"updated_at"`

    // Relationships
    User       User        `gorm:"foreignKey:UserID" json:"user,omitempty"`
    OrderItems []OrderItem `gorm:"foreignKey:OrderID" json:"order_items,omitempty"`
}

type OrderItem struct {
    ID        uuid.UUID `gorm:"type:uuid;primaryKey" json:"id"`
    OrderID   uuid.UUID `gorm:"type:uuid;not null" json:"order_id"`
    ProductID uuid.UUID `gorm:"type:uuid;not null" json:"product_id"`
    Quantity  int       `gorm:"not null" json:"quantity"`
    Price     float64   `gorm:"type:decimal(10,2);not null" json:"price"`

    // Relationships
    Product Product `gorm:"foreignKey:ProductID" json:"product,omitempty"`
}
```

## ⚠️ Best Practices
- ✅ Gunakan UUID untuk primary key (lebih secure)
- ✅ Selalu set `json:"-"` untuk password
- ✅ Gunakan pointer (*) untuk optional fields
- ✅ Buat method untuk business logic di model
- ✅ Gunakan GORM hooks (BeforeCreate, AfterCreate, dll)
- ❌ Jangan taruh database query di models
- ❌ Jangan taruh HTTP logic di models

## 🎓 Tips
- Gunakan `omitempty` untuk relationships agar JSON tidak bloat
- Buat constants untuk enum values (OrderStatus)
- Models hanya tentang data structure, bukan data access
EOF

# ========================================
# HANDLERS Directory Documentation
# ========================================
cat > handlers/README.md << 'EOF'
# HANDLERS Directory

## 📖 Filosofi
**"Handlers are the gateway between HTTP and your business logic"**. Filosofinya adalah memisahkan HTTP concerns (request/response handling) dari business logic. Handlers bertanggung jawab menerima HTTP request, validasi input, memanggil repository, dan mengembalikan HTTP response.

## 🎯 Definisi
Directory yang berisi HTTP handlers (atau controllers dalam MVC pattern). Handlers menerima HTTP requests, memproses data, berinteraksi dengan repositories, dan mengembalikan HTTP responses menggunakan Fiber.

## 💡 Tanggung Jawab
- Parse HTTP request (JSON body, query params, URL params)
- Validasi input
- Call repository methods (business logic)
- Handle errors
- Format & return HTTP response
- Set appropriate HTTP status codes

## 📝 Contoh Struktur
```
handlers/
├── user_handler.go      # User CRUD operations
├── product_handler.go   # Product operations
├── auth_handler.go      # Authentication (login, register)
└── README.md            # Dokumentasi ini
```

## 🔧 Contoh Kode

### user_handler.go
```go
package handlers

import (
    "myproject/models"
    "myproject/repositories"
    "myproject/utils"
    "github.com/gofiber/fiber/v2"
    "github.com/google/uuid"
    "golang.org/x/crypto/bcrypt"
)

type UserHandler struct {
    repo *repositories.UserRepository
}

func NewUserHandler(repo *repositories.UserRepository) *UserHandler {
    return &UserHandler{repo: repo}
}

// Create - POST /users
func (h *UserHandler) Create(c *fiber.Ctx) error {
    // 1. Parse request body
    var input struct {
        Email    string `json:"email" validate:"required,email"`
        Name     string `json:"name" validate:"required"`
        Password string `json:"password" validate:"required,min=6"`
    }

    if err := c.BodyParser(&input); err != nil {
        return utils.ErrorResponse(c, fiber.StatusBadRequest, "Invalid input: "+err.Error())
    }

    // 2. Validate input
    if err := utils.ValidateStruct(input); err != nil {
        return utils.ValidationErrorResponse(c, err)
    }

    // 3. Check if email exists
    existing, _ := h.repo.GetByEmail(input.Email)
    if existing != nil {
        return utils.ErrorResponse(c, fiber.StatusConflict, "Email already exists")
    }

    // 4. Hash password
    hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to process password")
    }

    // 5. Create user
    user := models.User{
        ID:       uuid.New(),
        Email:    input.Email,
        Name:     input.Name,
        Password: string(hashedPassword),
        Role:     "user",
        IsActive: true,
    }

    if err := h.repo.Create(&user); err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to create user")
    }

    // 6. Return response (hide password)
    user.Password = ""
    return utils.SuccessResponse(c, fiber.StatusCreated, "User created successfully", user)
}

// GetByID - GET /users/:id
func (h *UserHandler) GetByID(c *fiber.Ctx) error {
    // 1. Get ID from URL param
    id := c.Params("id")

    // 2. Validate UUID
    if _, err := uuid.Parse(id); err != nil {
        return utils.ErrorResponse(c, fiber.StatusBadRequest, "Invalid user ID")
    }

    // 3. Get user from database
    user, err := h.repo.GetByID(id)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusNotFound, "User not found")
    }

    // 4. Hide password
    user.Password = ""

    // 5. Return response
    return utils.SuccessResponse(c, fiber.StatusOK, "User fetched successfully", user)
}

// GetAll - GET /users
func (h *UserHandler) GetAll(c *fiber.Ctx) error {
    // 1. Parse query parameters
    role := c.Query("role")        // ?role=admin
    isActive := c.Query("is_active") // ?is_active=true

    // 2. Build filter
    filter := make(map[string]interface{})
    if role != "" {
        filter["role"] = role
    }
    if isActive == "true" {
        filter["is_active"] = true
    } else if isActive == "false" {
        filter["is_active"] = false
    }

    // 3. Get users
    users, err := h.repo.GetAll(filter)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to fetch users")
    }

    // 4. Hide passwords
    for i := range users {
        users[i].Password = ""
    }

    // 5. Return response
    return utils.SuccessResponse(c, fiber.StatusOK, "Users fetched successfully", fiber.Map{
        "users": users,
        "total": len(users),
    })
}

// Update - PUT /users/:id
func (h *UserHandler) Update(c *fiber.Ctx) error {
    // 1. Get ID
    id := c.Params("id")

    // 2. Check if user exists
    user, err := h.repo.GetByID(id)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusNotFound, "User not found")
    }

    // 3. Parse update data
    var input struct {
        Name     string `json:"name"`
        IsActive *bool  `json:"is_active"` // Pointer untuk optional
    }

    if err := c.BodyParser(&input); err != nil {
        return utils.ErrorResponse(c, fiber.StatusBadRequest, "Invalid input")
    }

    // 4. Update fields
    if input.Name != "" {
        user.Name = input.Name
    }
    if input.IsActive != nil {
        user.IsActive = *input.IsActive
    }

    // 5. Save to database
    if err := h.repo.Update(user); err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to update user")
    }

    // 6. Return response
    user.Password = ""
    return utils.SuccessResponse(c, fiber.StatusOK, "User updated successfully", user)
}

// Delete - DELETE /users/:id
func (h *UserHandler) Delete(c *fiber.Ctx) error {
    // 1. Get ID
    id := c.Params("id")

    // 2. Check if user exists
    user, err := h.repo.GetByID(id)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusNotFound, "User not found")
    }

    // 3. Business rule: Admin tidak bisa dihapus
    if user.IsAdmin() {
        return utils.ErrorResponse(c, fiber.StatusForbidden, "Cannot delete admin user")
    }

    // 4. Delete user
    if err := h.repo.Delete(id); err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to delete user")
    }

    // 5. Return response
    return utils.SuccessResponse(c, fiber.StatusOK, "User deleted successfully", nil)
}
```

### auth_handler.go
```go
package handlers

import (
    "myproject/models"
    "myproject/repositories"
    "myproject/utils"
    "github.com/gofiber/fiber/v2"
    "golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
    userRepo *repositories.UserRepository
}

func NewAuthHandler(userRepo *repositories.UserRepository) *AuthHandler {
    return &AuthHandler{userRepo: userRepo}
}

// Login - POST /auth/login
func (h *AuthHandler) Login(c *fiber.Ctx) error {
    var input struct {
        Email    string `json:"email" validate:"required,email"`
        Password string `json:"password" validate:"required"`
    }

    if err := c.BodyParser(&input); err != nil {
        return utils.ErrorResponse(c, fiber.StatusBadRequest, "Invalid input")
    }

    // Validate
    if err := utils.ValidateStruct(input); err != nil {
        return utils.ValidationErrorResponse(c, err)
    }

    // Get user by email
    user, err := h.userRepo.GetByEmail(input.Email)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid credentials")
    }

    // Check password
    if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
        return utils.ErrorResponse(c, fiber.StatusUnauthorized, "Invalid credentials")
    }

    // Check if active
    if !user.IsActive {
        return utils.ErrorResponse(c, fiber.StatusForbidden, "Account is inactive")
    }

    // Generate JWT token
    token, err := utils.GenerateJWT(user.ID.String(), user.Email, user.Role)
    if err != nil {
        return utils.ErrorResponse(c, fiber.StatusInternalServerError, "Failed to generate token")
    }

    return utils.SuccessResponse(c, fiber.StatusOK, "Login successful", fiber.Map{
        "token": token,
        "user": fiber.Map{
            "id":    user.ID,
            "email": user.Email,
            "name":  user.Name,
            "role":  user.Role,
        },
    })
}
```

## 🎯 HTTP Status Codes

| Status Code | Kapan Digunakan |
|------------|-----------------|
| 200 OK | Success GET, PUT, PATCH |
| 201 Created | Success POST (create new resource) |
| 204 No Content | Success DELETE |
| 400 Bad Request | Invalid input, validation error |
| 401 Unauthorized | Missing/invalid token |
| 403 Forbidden | Valid token, tapi tidak punya akses |
| 404 Not Found | Resource tidak ditemukan |
| 409 Conflict | Duplicate data (email exists) |
| 500 Internal Server Error | Server error |

## ⚠️ Best Practices
- ✅ Gunakan `c.BodyParser()` untuk parse JSON body
- ✅ Always validate input dengan validator
- ✅ Return appropriate HTTP status codes
- ✅ Hide sensitive data (password) dari response
- ✅ Use consistent response format
- ✅ Handle all possible errors
- ✅ Return error untuk propagate ke error handler
- ❌ Jangan expose internal error messages ke client

## 🎓 Tips Fiber
- `c.Params("id")` untuk URL parameters
- `c.Query("key")` untuk query strings
- `c.BodyParser(&struct)` untuk JSON body
- `return c.Status(code).JSON(data)` untuk response
- Return error akan di-handle oleh error handler middleware
EOF

# ========================================
# REPOSITORIES Directory Documentation
# ========================================
cat > repositories/README.md << 'EOF'
# REPOSITORIES Directory

## 📖 Filosofi
**"Abstract your data access layer"**. Repository pattern memisahkan business logic dari data access logic. Filosofinya adalah membuat abstraction layer antara aplikasi dan database, sehingga mudah untuk switch database atau mock data untuk testing.

## 🎯 Definisi
Directory yang berisi kode untuk berinteraksi dengan database. Repositories bertanggung jawab untuk semua operasi CRUD (Create, Read, Update, Delete) dan query kompleks ke database.

## 💡 Tanggung Jawab
- CRUD operations (Create, Read, Update, Delete)
- Database queries (SELECT, INSERT, UPDATE, DELETE)
- Filtering, sorting, pagination
- Transactions
- Complex joins dan relations
- Query optimization

## 📝 Contoh Struktur
```
repositories/
├── user_repository.go       # User data access
├── product_repository.go    # Product data access
├── order_repository.go      # Order data access
└── README.md                # Dokumentasi ini
```

## 🔧 Contoh Kode

### user_repository.go
```go
package repositories

import (
    "context"
    "myproject/models"
    "gorm.io/gorm"
)

type UserRepository struct {
    db *gorm.DB
}

func NewUserRepository(db *gorm.DB) *UserRepository {
    return &UserRepository{db: db}
}

// Create - Insert new user
func (r *UserRepository) Create(user *models.User) error {
    return r.db.Create(user).Error
}

// GetByID - Get user by ID
func (r *UserRepository) GetByID(id string) (*models.User, error) {
    var user models.User
    err := r.db.First(&user, "id = ?", id).Error
    if err != nil {
        return nil, err
    }
    return &user, nil
}

// GetByEmail - Get user by email
func (r *UserRepository) GetByEmail(email string) (*models.User, error) {
    var user models.User
    err := r.db.Where("email = ?", email).First(&user).Error
    if err != nil {
        if err == gorm.ErrRecordNotFound {
            return nil, nil // Return nil if not found
        }
        return nil, err
    }
    return &user, nil
}

// GetAll - Get all users with filters
func (r *UserRepository) GetAll(filter map[string]interface{}) ([]models.User, error) {
    var users []models.User
    query := r.db

    // Apply filters dynamically
    if role, ok := filter["role"].(string); ok && role != "" {
        query = query.Where("role = ?", role)
    }

    if isActive, ok := filter["is_active"].(bool); ok {
        query = query.Where("is_active = ?", isActive)
    }

    err := query.Find(&users).Error
    return users, err
}

// GetWithPagination - Get users with pagination
func (r *UserRepository) GetWithPagination(page, pageSize int) ([]models.User, int64, error) {
    var users []models.User
    var total int64

    // Count total
    r.db.Model(&models.User{}).Count(&total)

    // Get paginated data
    offset := (page - 1) * pageSize
    err := r.db.Offset(offset).Limit(pageSize).Find(&users).Error

    return users, total, err
}

// Update - Update user
func (r *UserRepository) Update(user *models.User) error {
    return r.db.Save(user).Error
}

// Delete - Delete user
func (r *UserRepository) Delete(id string) error {
    return r.db.Delete(&models.User{}, "id = ?", id).Error
}

// Search - Full text search
func (r *UserRepository) Search(keyword string) ([]models.User, error) {
    var users []models.User
    searchPattern := "%" + keyword + "%"
    err := r.db.Where("name ILIKE ? OR email ILIKE ?", searchPattern, searchPattern).Find(&users).Error
    return users, err
}
```

## ⚠️ Best Practices
- ✅ Always use context for cancellation
- ✅ Use transactions untuk operasi yang saling terkait
- ✅ Handle `gorm.ErrRecordNotFound` explicitly
- ✅ Use prepared statements (avoid SQL injection)
- ✅ Index kolom yang sering di-query
- ✅ Use pagination untuk large datasets
- ❌ Jangan expose repository errors langsung ke client
- ❌ Jangan query di loop (N+1 problem) - use Preload
- ❌ Jangan fetch all data tanpa limit
EOF

# ========================================
# MIDDLEWARES Directory Documentation
# ========================================
cat > middlewares/README.md << 'EOF'
# MIDDLEWARES Directory

## 📖 Filosofi
**"Middleware is the gatekeeper of your application"**. Filosofinya adalah memproses requests sebelum sampai ke handler dan responses sebelum dikirim ke client. Middleware memungkinkan separation of concerns untuk cross-cutting concerns seperti authentication, logging, CORS, dll.

## 🎯 Definisi
Directory yang berisi middleware functions yang dieksekusi sebelum atau sesudah handler. Middleware adalah fungsi yang memiliki akses ke context dan next function dalam request-response cycle.

## 💡 Tanggung Jawab
- Authentication & Authorization
- Request logging
- CORS handling
- Rate limiting
- Request validation
- Error handling
- Response compression
- Security headers

## 📝 Contoh Struktur
```
middlewares/
├── auth.go           # Authentication middleware
├── logger.go         # Request logging
├── cors.go           # CORS configuration
├── rate_limiter.go   # Rate limiting
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode

### auth.go
```go
package middlewares

import (
    "strings"
    "myproject/utils"
    "github.com/gofiber/fiber/v2"
)

// AuthMiddleware - Verify JWT token
func AuthMiddleware() fiber.Handler {
    return func(c *fiber.Ctx) error {
        // 1. Get token from header
        authHeader := c.Get("Authorization")
        if authHeader == "" {
            return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
                "status":  "error",
                "message": "Authorization header required",
            })
        }

        // 2. Extract token (format: "Bearer <token>")
        parts := strings.Split(authHeader, " ")
        if len(parts) != 2 || parts[0] != "Bearer" {
            return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
                "status":  "error",
                "message": "Invalid authorization format",
            })
        }

        token := parts[1]

        // 3. Validate token
        claims, err := utils.ValidateJWT(token)
        if err != nil {
            return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
                "status":  "error",
                "message": "Invalid or expired token",
            })
        }

        // 4. Set user info in context (locals)
        c.Locals("user_id", claims.UserID)
        c.Locals("email", claims.Email)
        c.Locals("role", claims.Role)

        // 5. Continue to next handler
        return c.Next()
    }
}

// AdminOnly - Check if user is admin
func AdminOnly() fiber.Handler {
    return func(c *fiber.Ctx) error {
        role := c.Locals("role")
        if role == nil {
            return c.Status(fiber.StatusUnauthorized).JSON(fiber.Map{
                "status":  "error",
                "message": "Unauthorized",
            })
        }

        if role != "admin" {
            return c.Status(fiber.StatusForbidden).JSON(fiber.Map{
                "status":  "error",
                "message": "Admin access required",
            })
        }

        return c.Next()
    }
}

// OptionalAuth - Auth optional, tidak block request
func OptionalAuth() fiber.Handler {
    return func(c *fiber.Ctx) error {
        authHeader := c.Get("Authorization")
        if authHeader != "" {
            parts := strings.Split(authHeader, " ")
            if len(parts) == 2 && parts[0] == "Bearer" {
                claims, err := utils.ValidateJWT(parts[1])
                if err == nil {
                    c.Locals("user_id", claims.UserID)
                    c.Locals("email", claims.Email)
                    c.Locals("role", claims.Role)
                }
            }
        }
        return c.Next()
    }
}
```

### logger.go
```go
package middlewares

import (
    "fmt"
    "time"
    "github.com/gofiber/fiber/v2"
)

// CustomLogger - Custom request logger
func CustomLogger() fiber.Handler {
    return func(c *fiber.Ctx) error {
        start := time.Now()

        // Process request
        err := c.Next()

        // Calculate duration
        duration := time.Since(start)

        // Log details
        fmt.Printf(
            "[%s] %s %s | Status: %d | Duration: %v | IP: %s\n",
            c.Method(),
            c.Path(),
            c.Protocol(),
            c.Response().StatusCode(),
            duration,
            c.IP(),
        )

        return err
    }
}
```

### cors.go
```go
package middlewares

import (
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/cors"
)

// CORS - Enable CORS with default config
func CORS() fiber.Handler {
    return cors.New(cors.Config{
        AllowOrigins: "*",
        AllowHeaders: "Origin, Content-Type, Accept, Authorization",
        AllowMethods: "GET, POST, PUT, DELETE, PATCH, OPTIONS",
    })
}

// CORSWithConfig - Configurable CORS
func CORSWithConfig(allowedOrigins []string) fiber.Handler {
    return cors.New(cors.Config{
        AllowOrigins: strings.Join(allowedOrigins, ","),
        AllowHeaders: "Origin, Content-Type, Accept, Authorization",
        AllowMethods: "GET, POST, PUT, DELETE, PATCH, OPTIONS",
        AllowCredentials: true,
    })
}
```

### rate_limiter.go
```go
package middlewares

import (
    "time"
    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/limiter"
)

// RateLimit - Limit requests per IP
func RateLimit(max int, expiration time.Duration) fiber.Handler {
    return limiter.New(limiter.Config{
        Max:        max,
        Expiration: expiration,
        KeyGenerator: func(c *fiber.Ctx) string {
            return c.IP()
        },
        LimitReached: func(c *fiber.Ctx) error {
            return c.Status(fiber.StatusTooManyRequests).JSON(fiber.Map{
                "status":  "error",
                "message": "Rate limit exceeded. Please try again later.",
            })
        },
    })
}

// Example usage: RateLimit(100, time.Minute) // 100 requests per minute
```

## 🎯 Middleware Execution Order
```go
app := fiber.New()

// Global middlewares (executed for all routes)
app.Use(recover.New())
app.Use(CustomLogger())
app.Use(CORS())

// Route-specific middleware
api := app.Group("/api/v1")

// Public routes
api.Post("/login", authHandler.Login)
api.Post("/register", authHandler.Register)

// Protected routes (with auth middleware)
protected := api.Group("/users", AuthMiddleware())
protected.Get("/", userHandler.GetAll)
protected.Get("/:id", userHandler.GetByID)

// Admin only routes
admin := api.Group("/admin", AuthMiddleware(), AdminOnly())
admin.Get("/users", userHandler.GetAll)
admin.Delete("/users/:id", userHandler.Delete)
```

## ⚠️ Best Practices
- ✅ Order matters - place auth before authorization
- ✅ Always call `c.Next()` to continue chain
- ✅ Use `c.Locals()` to pass data between middlewares
- ✅ Keep middleware focused on single responsibility
- ✅ Use Fiber's built-in middlewares when available
- ✅ Return error to stop execution
- ❌ Don't put business logic in middleware

## 🎓 Tips Fiber
- `c.Locals("key", value)` untuk set data
- `c.Locals("key")` untuk get data
- `return c.Next()` untuk continue
- Return error untuk stop execution
- Fiber punya banyak built-in middleware (logger, cors, limiter, compress, dll)
EOF

# ========================================
# UTILS Directory Documentation
# ========================================
cat > utils/README.md << 'EOF'
# UTILS Directory

## 📖 Filosofi
**"DRY - Don't Repeat Yourself"**. Filosofi utils adalah menyimpan fungsi-fungsi helper yang reusable di satu tempat, sehingga tidak perlu menulis kode yang sama berulang kali di berbagai tempat.

## 🎯 Definisi
Directory yang berisi utility functions dan helper functions yang bisa digunakan di berbagai bagian aplikasi. Functions di sini bersifat generic dan tidak terikat pada business logic tertentu.

## 💡 Tanggung Jawab
- Response formatting
- JWT token generation & validation
- Password hashing & verification
- Data validation
- String manipulation
- Date/time utilities
- File operations
- Random generators

## 📝 Contoh Struktur
```
utils/
├── response.go       # HTTP response helpers
├── jwt.go            # JWT token utilities
├── validator.go      # Custom validators
├── password.go       # Password utilities
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode

### response.go
```go
package utils

import "github.com/gofiber/fiber/v2"

type Response struct {
    Status  string      `json:"status"`
    Message string      `json:"message"`
    Data    interface{} `json:"data,omitempty"`
}

type ErrorDetail struct {
    Field   string `json:"field"`
    Message string `json:"message"`
}

// SuccessResponse - Standard success response
func SuccessResponse(c *fiber.Ctx, code int, message string, data interface{}) error {
    return c.Status(code).JSON(Response{
        Status:  "success",
        Message: message,
        Data:    data,
    })
}

// ErrorResponse - Standard error response
func ErrorResponse(c *fiber.Ctx, code int, message string) error {
    return c.Status(code).JSON(Response{
        Status:  "error",
        Message: message,
    })
}

// ValidationErrorResponse - For validation errors
func ValidationErrorResponse(c *fiber.Ctx, errors interface{}) error {
    return c.Status(fiber.StatusBadRequest).JSON(fiber.Map{
        "status":  "error",
        "message": "Validation failed",
        "errors":  errors,
    })
}

// PaginatedResponse - For paginated data
func PaginatedResponse(c *fiber.Ctx, data interface{}, page, pageSize int, total int64) error {
    totalPages := int(total) / pageSize
    if int(total)%pageSize != 0 {
        totalPages++
    }

    return c.Status(fiber.StatusOK).JSON(fiber.Map{
        "status":  "success",
        "message": "Data fetched successfully",
        "data":    data,
        "pagination": fiber.Map{
            "page":        page,
            "page_size":   pageSize,
            "total_items": total,
            "total_pages": totalPages,
        },
    })
}
```

### jwt.go
```go
package utils

import (
    "errors"
    "time"
    "github.com/golang-jwt/jwt/v5"
)

var jwtSecret = []byte("your-secret-key") // Ambil dari config

type Claims struct {
    UserID string `json:"user_id"`
    Email  string `json:"email"`
    Role   string `json:"role"`
    jwt.RegisteredClaims
}

// GenerateJWT - Create new JWT token
func GenerateJWT(userID, email, role string) (string, error) {
    claims := Claims{
        UserID: userID,
        Email:  email,
        Role:   role,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)), // 24 jam
            IssuedAt:  jwt.NewNumericDate(time.Now()),
            NotBefore: jwt.NewNumericDate(time.Now()),
        },
    }

    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(jwtSecret)
}

// ValidateJWT - Validate and parse JWT token
func ValidateJWT(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
        return jwtSecret, nil
    })

    if err != nil {
        return nil, err
    }

    if claims, ok := token.Claims.(*Claims); ok && token.Valid {
        return claims, nil
    }

    return nil, errors.New("invalid token")
}
```

### validator.go
```go
package utils

import (
    "github.com/go-playground/validator/v10"
)

var validate = validator.New()

// ValidateStruct - Validate struct using tags
func ValidateStruct(s interface{}) error {
    return validate.Struct(s)
}

// GetValidationErrors - Format validation errors
func GetValidationErrors(err error) []ErrorDetail {
    var errors []ErrorDetail

    if validationErrors, ok := err.(validator.ValidationErrors); ok {
        for _, e := range validationErrors {
            errors = append(errors, ErrorDetail{
                Field:   e.Field(),
                Message: getErrorMessage(e),
            })
        }
    }

    return errors
}

func getErrorMessage(e validator.FieldError) string {
    switch e.Tag() {
    case "required":
        return e.Field() + " is required"
    case "email":
        return e.Field() + " must be a valid email"
    case "min":
        return e.Field() + " must be at least " + e.Param() + " characters"
    case "max":
        return e.Field() + " must be at most " + e.Param() + " characters"
    default:
        return e.Field() + " is invalid"
    }
}
```

### password.go
```go
package utils

import (
    "golang.org/x/crypto/bcrypt"
)

// HashPassword - Hash password using bcrypt
func HashPassword(password string) (string, error) {
    bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
    return string(bytes), err
}

// CheckPassword - Verify password against hash
func CheckPassword(password, hash string) bool {
    err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
    return err == nil
}
```

## ⚠️ Best Practices
- ✅ Keep utils functions pure (no side effects)
- ✅ Make functions reusable and generic
- ✅ Add error handling
- ✅ Document functions with comments
- ✅ Use descriptive function names
- ❌ Don't put business logic in utils
- ❌ Don't access database in utils
EOF

# ========================================
# ROUTES Directory Documentation
# ========================================
cat > routes/README.md << 'EOF'
# ROUTES Directory

## 📖 Filosofi
**"Routes are the map of your API"**. Filosofi routes adalah mendefinisikan semua endpoint API di satu tempat yang terorganisir, sehingga mudah untuk melihat struktur API secara keseluruhan dan mengelola versioning.

## 🎯 Definisi
Directory yang berisi definisi semua HTTP routes/endpoints aplikasi. Routes menghubungkan URL paths dengan handler functions dan middlewares.

## 💡 Tanggung Jawab
- Define URL paths and HTTP methods
- Map routes to handlers
- Apply middlewares to routes
- Group related routes
- API versioning
- Route documentation

## 📝 Contoh Struktur
```
routes/
├── routes.go         # Main routes setup
└── README.md         # Dokumentasi ini
```

## 🔧 Contoh Kode

### routes.go
```go
package routes

import (
    "myproject/handlers"
    "myproject/middlewares"
    "github.com/gofiber/fiber/v2"
)

func SetupRoutes(
    app *fiber.App,
    userHandler *handlers.UserHandler,
    productHandler *handlers.ProductHandler,
    authHandler *handlers.AuthHandler,
) {
    // Health check
    app.Get("/health", func(c *fiber.Ctx) error {
        return c.JSON(fiber.Map{
            "status":  "ok",
            "message": "Server is running",
        })
    })

    // API v1 routes
    v1 := app.Group("/api/v1")

    // Public routes
    auth := v1.Group("/auth")
    auth.Post("/register", authHandler.Register)
    auth.Post("/login", authHandler.Login)
    auth.Post("/forgot-password", authHandler.ForgotPassword)
    auth.Post("/reset-password", authHandler.ResetPassword)

    // Protected routes
    protected := v1.Group("", middlewares.AuthMiddleware())

    // User routes
    users := protected.Group("/users")
    users.Get("/", userHandler.GetAll)           // GET /api/v1/users
    users.Get("/:id", userHandler.GetByID)       // GET /api/v1/users/:id
    users.Put("/:id", userHandler.Update)        // PUT /api/v1/users/:id
    users.Delete("/:id", userHandler.Delete)     // DELETE /api/v1/users/:id

    // Product routes
    products := protected.Group("/products")
    products.Get("/", productHandler.GetAll)
    products.Get("/:id", productHandler.GetByID)
    products.Post("/", productHandler.Create)
    products.Put("/:id", productHandler.Update)
    products.Delete("/:id", productHandler.Delete)

    // Profile routes
    profile := protected.Group("/profile")
    profile.Get("/", userHandler.GetProfile)
    profile.Put("/", userHandler.UpdateProfile)
    profile.Put("/password", userHandler.ChangePassword)

    // Admin only routes
    admin := v1.Group("/admin", middlewares.AuthMiddleware(), middlewares.AdminOnly())
    admin.Get("/users", userHandler.GetAll)
    admin.Delete("/users/:id", userHandler.Delete)
    admin.Get("/analytics", userHandler.GetAnalytics)
}
```

## 🎯 Route Patterns & Best Practices

### RESTful Conventions
```
GET    /api/v1/users          → Get all users
GET    /api/v1/users/:id      → Get single user
POST   /api/v1/users          → Create user
PUT    /api/v1/users/:id      → Update user (full)
PATCH  /api/v1/users/:id      → Update user (partial)
DELETE /api/v1/users/:id      → Delete user
```

## ⚠️ Best Practices
- ✅ Use RESTful conventions when possible
- ✅ Version your API (/api/v1, /api/v2)
- ✅ Group related routes
- ✅ Use meaningful URL paths
- ✅ Apply middlewares efficiently
- ✅ Document your routes
- ❌ Don't use verbs in URLs
- ❌ Don't nest too deep

## 🎓 Tips Fiber
- `app.Get()`, `app.Post()`, `app.Put()`, `app.Delete()` untuk HTTP methods
- `app.Group()` untuk group routes
- Middleware applied dengan chaining
- Fiber lebih cepat dan memory efficient
EOF

# ========================================
# Create example files
# ========================================

# Create main.go
cat > cmd/main.go << 'EOF'
package main

import (
    "log"
    "os"
    "os/signal"

    "github.com/gofiber/fiber/v2"
    "github.com/gofiber/fiber/v2/middleware/logger"
    "github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
    // TODO: Initialize config, database, repositories, handlers

    app := fiber.New(fiber.Config{
        AppName: "My API v1.0.0",
    })

    // Middlewares
    app.Use(recover.New())
    app.Use(logger.New())

    // Health check
    app.Get("/health", func(c *fiber.Ctx) error {
        return c.JSON(fiber.Map{
            "status":  "ok",
            "message": "Server is running",
        })
    })

    // Graceful shutdown
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    go func() {
        <-c
        log.Println("🛑 Gracefully shutting down...")
        app.Shutdown()
    }()

    log.Println("🚀 Server starting on :3000")
    if err := app.Listen(":3000"); err != nil {
        log.Fatal("❌ Failed to start server:", err)
    }
}
EOF

# Create .env.example
cat > .env.example << 'EOF'
# Server Configuration
PORT=3000
ENVIRONMENT=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=your_password
DB_NAME=myapp

# JWT Configuration
JWT_SECRET=your-super-secret-key-change-this

# External Services (Optional)
PAYMENT_API_KEY=
SMTP_HOST=
SMTP_PORT=
EOF

# Create .gitignore
cat > .gitignore << 'EOF'
# Binaries
*.exe
*.exe~
*.dll
*.so
*.dylib
bin/
dist/

# Environment variables
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Go
vendor/
*.test
*.out

# Logs
*.log
logs/

# Temporary files
tmp/
temp/
EOF

# Create go.mod
cat > go.mod << 'EOF'
module myproject

go 1.21

require (
    github.com/gofiber/fiber/v2 v2.52.0
    github.com/google/uuid v1.5.0
    github.com/joho/godotenv v1.5.1
    github.com/golang-jwt/jwt/v5 v5.2.0
    github.com/go-playground/validator/v10 v10.16.0
    golang.org/x/crypto v0.17.0
    gorm.io/driver/postgres v1.5.4
    gorm.io/gorm v1.25.5
)
EOF

# Create README.md
cat > README.md << 'EOF'
# My Go Project

Clean Architecture Simple - Fast Development Structure with Fiber

## 📁 Project Structure
```
.
├── cmd/                # Entry point
├── config/             # Configuration
├── models/             # Database models
├── handlers/           # HTTP handlers
├── repositories/       # Data access layer
├── middlewares/        # HTTP middlewares
├── utils/              # Helper functions
└── routes/             # Route definitions
```

## 🚀 Quick Start

1. **Clone & Setup**
```bash
   cd myproject
   cp .env.example .env
   # Edit .env with your configuration
```

2. **Install Dependencies**
```bash
   go mod download
```

3. **Run**
```bash
   go run cmd/main.go
```

4. **Test**
```bash
   curl http://localhost:3000/health
```

## 📖 Documentation

Each folder contains a README.md with:
- Philosophy
- Definition
- Examples
- Best practices

Start reading from:
1. `cmd/README.md` - Entry point
2. `models/README.md` - Data structures
3. `handlers/README.md` - Business logic
4. `routes/README.md` - API endpoints

## 🛠️ Development

### Add New Feature

1. Create model in `models/`
2. Create repository in `repositories/`
3. Create handler in `handlers/`
4. Register routes in `routes/`

## 📚 Tech Stack

- **Framework**: Fiber (Fast Express-like framework)
- **ORM**: GORM
- **Database**: PostgreSQL
- **Auth**: JWT
- **Validation**: go-playground/validator

## 🎯 Why Fiber?

- ⚡ Extremely fast (built on fasthttp)
- 🎨 Express.js-like syntax
- 🔧 Zero memory allocation router
- 💪 Robust middleware support
- 📝 Great documentation

## 🤝 Contributing

1. Read documentation in each folder
2. Follow existing patterns
3. Keep it simple

## 📝 License

MIT
EOF

echo ""
echo "================================================"
echo "✅ Structure generated successfully!"
echo "================================================"
echo ""
echo "📂 Project created at: $PROJECT_NAME/"
echo ""
echo "📖 Next steps:"
echo "  1. cd $PROJECT_NAME"
echo "  2. Read README.md"
echo "  3. Read cmd/README.md to understand the flow"
echo "  4. cp .env.example .env"
echo "  5. go mod download"
echo "  6. go run cmd/main.go"
echo ""
echo "💡 Each folder has detailed documentation in README.md"
echo "   Start with cmd/README.md → models/README.md → handlers/README.md"
echo ""
echo "🚀 Using Fiber - The Express.js of Go!"
echo "🎉 Happy coding!"
EOF

chmod +x generate-simple-structure.sh

echo ""
echo "✅ Shell script created: generate-simple-structure.sh"
echo ""
echo "📝 Usage:"
echo "   bash generate-simple-structure.sh [project-name]"
echo ""
echo "Example:"
echo "   bash generate-simple-structure.sh my-fiber-api"
echo ""
