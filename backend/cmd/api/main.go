package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gestao-transporte/backend/internal/config"
	"github.com/gestao-transporte/backend/internal/handlers"
	"github.com/gestao-transporte/backend/internal/middleware"
	"github.com/gestao-transporte/backend/internal/repository"
	"github.com/joho/godotenv"
	"github.com/rs/cors"
)

func main() {
	_ = godotenv.Load()

	db, err := config.ConnectDB()
	if err != nil {
		log.Fatal(err)
	}
	defer db.Close()

	empresaRepo := repository.NewEmpresaRepository(db)
	usuarioRepo := repository.NewUsuarioRepository(db)
	escolaRepo := repository.NewEscolaRepository(db)
	alunoRepo := repository.NewAlunoRepository(db)
	mensalidadeRepo := repository.NewMensalidadeRepository(db)

	if err := seed(db, empresaRepo, usuarioRepo, escolaRepo, alunoRepo); err != nil {
		log.Printf("Seed: %v", err)
	}

	authHandler := handlers.NewAuthHandler(usuarioRepo, empresaRepo)
	empresaHandler := handlers.NewEmpresaHandler(empresaRepo)
	escolaHandler := handlers.NewEscolaHandler(escolaRepo)
	alunoHandler := handlers.NewAlunoHandler(alunoRepo)
	mensalidadeHandler := handlers.NewMensalidadeHandler(mensalidadeRepo, alunoRepo)

	mux := http.NewServeMux()

	// Auth
	mux.HandleFunc("POST /api/login", authHandler.Login)
	mux.Handle("GET /api/me", middleware.Auth(http.HandlerFunc(authHandler.Me)))

	// Empresas
	mux.Handle("GET /api/empresas", middleware.Auth(http.HandlerFunc(empresaHandler.List)))
	mux.Handle("GET /api/empresas/{id}", middleware.Auth(http.HandlerFunc(empresaHandler.GetByID)))

	// Escolas
	mux.Handle("GET /api/escolas", middleware.Auth(http.HandlerFunc(escolaHandler.List)))
	mux.Handle("POST /api/escolas", middleware.Auth(http.HandlerFunc(escolaHandler.Create)))
	mux.Handle("PUT /api/escolas/{id}", middleware.Auth(http.HandlerFunc(escolaHandler.Update)))
	mux.Handle("DELETE /api/escolas/{id}", middleware.Auth(http.HandlerFunc(escolaHandler.Delete)))

	// Alunos
	mux.Handle("GET /api/alunos", middleware.Auth(http.HandlerFunc(alunoHandler.List)))
	mux.Handle("POST /api/alunos", middleware.Auth(http.HandlerFunc(alunoHandler.Create)))
	mux.Handle("PUT /api/alunos/{id}", middleware.Auth(http.HandlerFunc(alunoHandler.Update)))
	mux.Handle("DELETE /api/alunos/{id}", middleware.Auth(http.HandlerFunc(alunoHandler.Delete)))

	// Mensalidades
	mux.Handle("GET /api/mensalidades", middleware.Auth(http.HandlerFunc(mensalidadeHandler.List)))
	mux.Handle("POST /api/mensalidades", middleware.Auth(http.HandlerFunc(mensalidadeHandler.Create)))
	mux.Handle("POST /api/mensalidades/gerar", middleware.Auth(http.HandlerFunc(mensalidadeHandler.BulkGenerate)))
	mux.Handle("PUT /api/mensalidades/{id}", middleware.Auth(http.HandlerFunc(mensalidadeHandler.Update)))
	mux.Handle("DELETE /api/mensalidades/{id}", middleware.Auth(http.HandlerFunc(mensalidadeHandler.Delete)))

	// CORS
	handler := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	}).Handler(mux)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Servidor rodando em http://localhost:%s", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}
