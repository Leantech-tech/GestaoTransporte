package main

import (
	"log"
	"net/http"
	"os"
	"strings"

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
	colaboradorRepo := repository.NewColaboradorRepository(db)
	veiculoRepo := repository.NewVeiculoRepository(db)
	linhaRepo := repository.NewLinhaRepository(db)
	mensalidadeRepo := repository.NewMensalidadeRepository(db)

	if err := seed(db, empresaRepo, usuarioRepo, escolaRepo, alunoRepo); err != nil {
		log.Printf("Seed: %v", err)
	}

	authHandler := handlers.NewAuthHandler(usuarioRepo, empresaRepo)
	empresaHandler := handlers.NewEmpresaHandler(empresaRepo)
	usuarioHandler := handlers.NewUsuarioHandler(usuarioRepo)
	escolaHandler := handlers.NewEscolaHandler(escolaRepo)
	alunoHandler := handlers.NewAlunoHandler(alunoRepo)
	colaboradorHandler := handlers.NewColaboradorHandler(colaboradorRepo)
	veiculoHandler := handlers.NewVeiculoHandler(veiculoRepo)
	linhaHandler := handlers.NewLinhaHandler(linhaRepo)
	mensalidadeHandler := handlers.NewMensalidadeHandler(mensalidadeRepo, alunoRepo)

	mux := http.NewServeMux()

	// Auth
	mux.HandleFunc("/api/login", authHandler.Login)
	mux.Handle("/api/me", middleware.Auth(http.HandlerFunc(authHandler.Me)))

	// Empresas (GET list | POST create)
	mux.Handle("/api/empresas", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			empresaHandler.List(w, r)
		case http.MethodPost:
			empresaHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Empresas by ID (GET | PUT | DELETE)
	mux.Handle("/api/empresas/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/empresas/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodGet:
			empresaHandler.GetByID(w, r)
		case http.MethodPut:
			empresaHandler.Update(w, r)
		case http.MethodDelete:
			empresaHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Usuários (GET list | POST create)
	mux.Handle("/api/usuarios", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			usuarioHandler.List(w, r)
		case http.MethodPost:
			usuarioHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Usuários by ID (PUT | DELETE)
	mux.Handle("/api/usuarios/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/usuarios/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			usuarioHandler.Update(w, r)
		case http.MethodDelete:
			usuarioHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Escolas (GET list | POST create)
	mux.Handle("/api/escolas", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			escolaHandler.List(w, r)
		case http.MethodPost:
			escolaHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Escolas by ID (PUT | DELETE)
	mux.Handle("/api/escolas/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/escolas/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			escolaHandler.Update(w, r)
		case http.MethodDelete:
			escolaHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Alunos (GET list | POST create)
	mux.Handle("/api/alunos", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			alunoHandler.List(w, r)
		case http.MethodPost:
			alunoHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Alunos by ID (PUT | DELETE)
	mux.Handle("/api/alunos/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/alunos/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			alunoHandler.Update(w, r)
		case http.MethodDelete:
			alunoHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Colaboradores (GET list | POST create)
	mux.Handle("/api/colaboradores", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			colaboradorHandler.List(w, r)
		case http.MethodPost:
			colaboradorHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Colaboradores by ID (PUT | DELETE)
	mux.Handle("/api/colaboradores/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/colaboradores/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			colaboradorHandler.Update(w, r)
		case http.MethodDelete:
			colaboradorHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Veículos (GET list | POST create)
	mux.Handle("/api/veiculos", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			veiculoHandler.List(w, r)
		case http.MethodPost:
			veiculoHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Veículos by ID (PUT | DELETE)
	mux.Handle("/api/veiculos/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/veiculos/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			veiculoHandler.Update(w, r)
		case http.MethodDelete:
			veiculoHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Linhas (GET list | POST create)
	mux.Handle("/api/linhas", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			linhaHandler.List(w, r)
		case http.MethodPost:
			linhaHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Linhas by ID (PUT | DELETE)
	mux.Handle("/api/linhas/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/linhas/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			linhaHandler.Update(w, r)
		case http.MethodDelete:
			linhaHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Mensalidades (GET list | POST create)
	mux.Handle("/api/mensalidades", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			mensalidadeHandler.List(w, r)
		case http.MethodPost:
			mensalidadeHandler.Create(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Mensalidades gerar (bulk generate)
	mux.Handle("/api/mensalidades/gerar", middleware.Auth(http.HandlerFunc(mensalidadeHandler.BulkGenerate)))

	// Mensalidades by ID (PUT | DELETE)
	mux.Handle("/api/mensalidades/", middleware.Auth(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if !strings.HasPrefix(r.URL.Path, "/api/mensalidades/") {
			http.NotFound(w, r)
			return
		}
		switch r.Method {
		case http.MethodPut:
			mensalidadeHandler.Update(w, r)
		case http.MethodDelete:
			mensalidadeHandler.Delete(w, r)
		default:
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		}
	})))

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte("ok"))
	})

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
