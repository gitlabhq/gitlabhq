package version

import "fmt"

var version = "unknown"
var build = "unknown"
var schema = "gitlab-workhorse (%s)-(%s)"

func SetVersion(v, b string) {
	version = v
	build = b
}

func GetUserAgent() string {
	return GetApplicationVersion()
}

func GetApplicationVersion() string {
	return fmt.Sprintf(schema, version, build)
}
