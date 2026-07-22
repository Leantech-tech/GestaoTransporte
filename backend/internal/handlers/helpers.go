package handlers

import (
	"net/http"

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
