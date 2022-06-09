# go-is-svg

Tiny package to verify if a given file buffer is an SVG image in Go (golang).

## Installation

```bash
go get -u github.com/h2non/go-is-svg
```

## Example

```go
package main

import (
	"fmt"
	"os"

	svg "github.com/h2non/go-is-svg"
)

func main() {
	buf, err := os.ReadFile("_example/example.svg")
	if err != nil {
		fmt.Printf("Error: %s\n", err)
		return
	}

	if svg.Is(buf) {
		fmt.Println("File is an SVG")
	} else {
		fmt.Println("File is NOT an SVG")
	}
}
```

Run example:
```bash
go run _example/example.go
```

## License

MIT - Tomas Aparicio
