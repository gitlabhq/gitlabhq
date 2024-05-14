// Package version provides functionality related to the version information of the application.
package version

import "fmt"

var version = "unknown"
var build = "unknown"
var schema = "gitlab-workhorse (%s)-(%s)"

// SetVersion sets the version and build information for the application.
func SetVersion(v, b string) {
	version = v
	build = b
}

// GetUserAgent returns the user agent string for the application.
func GetUserAgent() string {
	return GetApplicationVersion()
}

// GetApplicationVersion returns the application version string.
func GetApplicationVersion() string {
	return fmt.Sprintf(schema, version, build)
}
