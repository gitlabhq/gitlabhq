module gitlab.com/gitlab-org/gitlab-workhorse

go 1.13

require (
	github.com/Azure/azure-storage-blob-go v0.11.1-0.20201209121048-6df5d9af221d
	github.com/BurntSushi/toml v0.3.1
	github.com/FZambia/sentinel v1.0.0
	github.com/alecthomas/chroma v0.7.3
	github.com/aws/aws-sdk-go v1.36.1
	github.com/dgrijalva/jwt-go v3.2.0+incompatible
	github.com/disintegration/imaging v1.6.2
	github.com/golang/gddo v0.0.0-20190419222130-af0f2af80721
	github.com/golang/protobuf v1.4.3
	github.com/gomodule/redigo v2.0.0+incompatible
	github.com/gorilla/websocket v1.4.1
	github.com/grpc-ecosystem/go-grpc-middleware v1.2.2
	github.com/grpc-ecosystem/go-grpc-prometheus v1.2.0
	github.com/johannesboyne/gofakes3 v0.0.0-20200510090907-02d71f533bec
	github.com/jpillora/backoff v1.0.0
	github.com/mitchellh/copystructure v1.0.0
	github.com/prometheus/client_golang v1.8.0
	github.com/rafaeljusto/redigomock v0.0.0-20190202135759-257e089e14a1
	github.com/sebest/xff v0.0.0-20160910043805-6c115e0ffa35
	github.com/shabbyrobe/gocovmerge v0.0.0-20190829150210-3e036491d500 // indirect
	github.com/sirupsen/logrus v1.7.0
	github.com/smartystreets/goconvey v1.6.4
	github.com/stretchr/testify v1.6.1
	gitlab.com/gitlab-org/gitaly v1.74.0
	gitlab.com/gitlab-org/labkit v1.0.0
	gocloud.dev v0.21.1-0.20201223184910-5094f54ed8bb
	golang.org/x/image v0.0.0-20191009234506-e7c1f5e7dbb8
	golang.org/x/lint v0.0.0-20200302205851-738671d3881b
	golang.org/x/net v0.0.0-20201224014010-6772e930b67b
	golang.org/x/sys v0.0.0-20210110051926-789bb1bd4061 // indirect
	golang.org/x/text v0.3.5 // indirect
	golang.org/x/tools v0.0.0-20201203202102-a1a1cbeaa516
	google.golang.org/genproto v0.0.0-20210111234610-22ae2b108f89 // indirect
	google.golang.org/grpc v1.34.1
	google.golang.org/grpc/examples v0.0.0-20201226181154-53788aa5dcb4 // indirect
	honnef.co/go/tools v0.0.1-2020.1.5
)

// go get tries to enforce semantic version compatibility via module paths.
// We can't upgrade to Gitaly v13.x.x from v1.x.x without using a manual override.
// See https://gitlab.com/gitlab-org/gitaly/-/issues/3177 for more details.
replace gitlab.com/gitlab-org/gitaly => gitlab.com/gitlab-org/gitaly v1.87.1-0.20201001041716-3f5e218def93
