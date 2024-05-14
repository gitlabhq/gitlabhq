// Package secret provides functionality for handling JWT tokens
package secret

import (
	"fmt"

	"github.com/golang-jwt/jwt/v5"
)

var (
	// DefaultClaims specifies the default JWT claims
	DefaultClaims = jwt.RegisteredClaims{Issuer: "gitlab-workhorse"}
)

// JWTTokenString generates a JWT token string with the provided claims
func JWTTokenString(claims jwt.Claims) (string, error) {
	secretBytes, err := Bytes()
	if err != nil {
		return "", fmt.Errorf("secret.JWTTokenString: %v", err)
	}

	tokenString, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(secretBytes)
	if err != nil {
		return "", fmt.Errorf("secret.JWTTokenString: sign JWT: %v", err)
	}

	return tokenString, nil
}
