package auth

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

var jwtSecret = []byte(getEnv("JWT_SECRET", "segredo-local"))

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

type Claims struct {
	UsuarioID  string `json:"usuario_id"`
	EmpresaID  string `json:"empresa_id"`
	Perfil     string `json:"perfil"`
	jwt.RegisteredClaims
}

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	return string(bytes), err
}

func CheckPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func GenerateToken(usuarioID, empresaID, perfil string) (string, error) {
	claims := Claims{
		UsuarioID: usuarioID,
		EmpresaID: empresaID,
		Perfil:    perfil,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

func ParseToken(tokenStr string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenStr, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("método de assinatura inesperado: %v", token.Header["alg"])
		}
		return jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, fmt.Errorf("token inválido")
}

// SenhaSuporte gera a senha no formato contínuo: diaSemana+ano+mes+dia
// Convenção: domingo = 1, segunda = 2, ..., sábado = 7.
func SenhaSuporte(hoje time.Time) string {
	diaSemana := strconv.Itoa(int(hoje.Weekday()) + 1)
	ano := strconv.Itoa(hoje.Year())
	mes := fmt.Sprintf("%02d", hoje.Month())
	dia := fmt.Sprintf("%02d", hoje.Day())
	return strings.Join([]string{diaSemana, ano, mes, dia}, "")
}

// SenhaSuporteAntiga gera o formato legado com hífens, mantido apenas para compatibilidade.
func SenhaSuporteAntiga(hoje time.Time) string {
	diaSemana := strconv.Itoa(int(hoje.Weekday()) + 1)
	ano := strconv.Itoa(hoje.Year())
	mes := fmt.Sprintf("%02d", hoje.Month())
	dia := fmt.Sprintf("%02d", hoje.Day())
	return strings.Join([]string{diaSemana, ano, mes, dia}, "-")
}
