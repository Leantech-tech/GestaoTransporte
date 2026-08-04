package handlers

import (
	"net/http"
	"strings"

	"github.com/gestao-transporte/backend/internal/middleware"
)

func empresaIDFromClaims(r *http.Request) string {
	claims := middleware.ClaimsFromContext(r)
	if claims == nil {
		return ""
	}
	if claims.Perfil == "suporte" {
		return ""
	}
	return claims.EmpresaID
}

func pathValue(r *http.Request, key string) string {
	if key != "id" {
		return ""
	}
	path := strings.Trim(r.URL.Path, "/")
	parts := strings.Split(path, "/")
	if len(parts) < 3 {
		return ""
	}
	return parts[len(parts)-1]
}
