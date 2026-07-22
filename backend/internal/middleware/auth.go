package middleware

import (
	"context"
	"net/http"
	"strings"

	"github.com/gestao-transporte/backend/internal/auth"
)

type contextKey string

const ContextKeyClaims contextKey = "claims"

func Auth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			writeError(w, http.StatusUnauthorized, "token não fornecido")
			return
		}

		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			writeError(w, http.StatusUnauthorized, "formato de token inválido")
			return
		}

		claims, err := auth.ParseToken(parts[1])
		if err != nil {
			writeError(w, http.StatusUnauthorized, "token inválido ou expirado")
			return
		}

		ctx := context.WithValue(r.Context(), ContextKeyClaims, claims)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func ClaimsFromContext(r *http.Request) *auth.Claims {
	claims, _ := r.Context().Value(ContextKeyClaims).(*auth.Claims)
	return claims
}

func writeError(w http.ResponseWriter, status int, message string) {
	w.WriteHeader(status)
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte(`{"error":"` + message + `"}`))
}
