module gitlab.com/gitlab-org/gitlab/workhorse

go 1.20

require (
	github.com/Azure/azure-sdk-for-go/sdk/storage/azblob v1.3.1
	github.com/BurntSushi/toml v1.3.2
	github.com/alecthomas/chroma/v2 v2.13.0
	github.com/aws/aws-sdk-go v1.51.14
	github.com/disintegration/imaging v1.6.2
	github.com/getsentry/raven-go v0.2.0
	github.com/golang-jwt/jwt/v5 v5.2.1
	github.com/golang/gddo v0.0.0-20210115222349-20d68f94ee1f
	github.com/gorilla/websocket v1.5.1
	github.com/grpc-ecosystem/go-grpc-prometheus v1.2.0
	github.com/johannesboyne/gofakes3 v0.0.0-20240217095638-c55a48f17be6
	github.com/jpillora/backoff v1.0.0
	github.com/mitchellh/copystructure v1.2.0
	github.com/prometheus/client_golang v1.19.0
	github.com/redis/go-redis/v9 v9.5.1
	github.com/sebest/xff v0.0.0-20210106013422-671bd2870b3a
	github.com/sirupsen/logrus v1.9.3
	github.com/smartystreets/goconvey v1.8.1
	github.com/stretchr/testify v1.9.0
	gitlab.com/gitlab-org/gitaly/v16 v16.9.2
	gitlab.com/gitlab-org/labkit v1.21.0
	gocloud.dev v0.37.0
	golang.org/x/image v0.15.0
	golang.org/x/lint v0.0.0-20210508222113-6edffad5e616
	golang.org/x/net v0.22.0
	golang.org/x/oauth2 v0.18.0
	golang.org/x/tools v0.19.0
	google.golang.org/grpc v1.62.1
	google.golang.org/protobuf v1.33.0
	honnef.co/go/tools v0.4.7
)

require (
	cloud.google.com/go v0.112.1 // indirect
	cloud.google.com/go/compute v1.25.0 // indirect
	cloud.google.com/go/compute/metadata v0.2.3 // indirect
	cloud.google.com/go/iam v1.1.6 // indirect
	cloud.google.com/go/monitoring v1.18.0 // indirect
	cloud.google.com/go/profiler v0.1.0 // indirect
	cloud.google.com/go/storage v1.39.1 // indirect
	cloud.google.com/go/trace v1.10.5 // indirect
	contrib.go.opencensus.io/exporter/stackdriver v0.13.14 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/azcore v1.10.0 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/azidentity v1.5.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/internal v1.5.2 // indirect
	github.com/Azure/go-autorest v14.2.0+incompatible // indirect
	github.com/Azure/go-autorest/autorest/to v0.4.0 // indirect
	github.com/AzureAD/microsoft-authentication-library-for-go v1.2.2 // indirect
	github.com/DataDog/datadog-go v4.4.0+incompatible // indirect
	github.com/DataDog/sketches-go v1.0.0 // indirect
	github.com/Microsoft/go-winio v0.6.1 // indirect
	github.com/beevik/ntp v1.3.0 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/census-instrumentation/opencensus-proto v0.4.1 // indirect
	github.com/certifi/gocertifi v0.0.0-20210507211836-431795d63e8d // indirect
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/client9/reopen v1.0.0 // indirect
	github.com/davecgh/go-spew v1.1.2-0.20180830191138-d8f796af33cc // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/dlclark/regexp2 v1.11.0 // indirect
	github.com/felixge/httpsnoop v1.0.4 // indirect
	github.com/go-logr/logr v1.4.1 // indirect
	github.com/go-logr/stdr v1.2.2 // indirect
	github.com/go-ole/go-ole v1.2.6 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da // indirect
	github.com/golang/protobuf v1.5.4 // indirect
	github.com/google/pprof v0.0.0-20240117000934-35fc243c5815 // indirect
	github.com/google/s2a-go v0.1.7 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/google/wire v0.6.0 // indirect
	github.com/googleapis/enterprise-certificate-proxy v0.3.2 // indirect
	github.com/googleapis/gax-go/v2 v2.12.2 // indirect
	github.com/gopherjs/gopherjs v1.17.2 // indirect
	github.com/grpc-ecosystem/go-grpc-middleware v1.4.0 // indirect
	github.com/grpc-ecosystem/go-grpc-middleware/v2 v2.0.0 // indirect
	github.com/hashicorp/yamux v0.1.2-0.20220728231024-8f49b6f63f18 // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
	github.com/jtolds/gls v4.20.0+incompatible // indirect
	github.com/kylelemons/godebug v1.1.0 // indirect
	github.com/lightstep/lightstep-tracer-common/golang/gogo v0.0.0-20210210170715-a8dfcb80d3a7 // indirect
	github.com/lightstep/lightstep-tracer-go v0.25.0 // indirect
	github.com/lufia/plan9stats v0.0.0-20211012122336-39d0f177ccd0 // indirect
	github.com/mitchellh/reflectwalk v1.0.2 // indirect
	github.com/oklog/ulid/v2 v2.0.2 // indirect
	github.com/opentracing/opentracing-go v1.2.0 // indirect
	github.com/philhofer/fwd v1.1.1 // indirect
	github.com/pkg/browser v0.0.0-20240102092130-5ac0b6a4141c // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/pmezard/go-difflib v1.0.1-0.20181226105442-5d4384ee4fb2 // indirect
	github.com/power-devops/perfstat v0.0.0-20210106213030-5aafc221ea8c // indirect
	github.com/prometheus/client_model v0.5.0 // indirect
	github.com/prometheus/common v0.48.0 // indirect
	github.com/prometheus/procfs v0.12.0 // indirect
	github.com/prometheus/prometheus v0.50.1 // indirect
	github.com/ryszard/goskiplist v0.0.0-20150312221310-2dfbae5fcf46 // indirect
	github.com/shabbyrobe/gocovmerge v0.0.0-20190829150210-3e036491d500 // indirect
	github.com/shirou/gopsutil/v3 v3.21.12 // indirect
	github.com/smarty/assertions v1.15.0 // indirect
	github.com/tinylib/msgp v1.1.2 // indirect
	github.com/tklauser/go-sysconf v0.3.9 // indirect
	github.com/tklauser/numcpus v0.3.0 // indirect
	github.com/uber/jaeger-client-go v2.30.0+incompatible // indirect
	github.com/uber/jaeger-lib v2.4.1+incompatible // indirect
	github.com/yusufpapurcu/wmi v1.2.2 // indirect
	go.opencensus.io v0.24.0 // indirect
	go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc v0.49.0 // indirect
	go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp v0.49.0 // indirect
	go.opentelemetry.io/otel v1.24.0 // indirect
	go.opentelemetry.io/otel/metric v1.24.0 // indirect
	go.opentelemetry.io/otel/trace v1.24.0 // indirect
	go.uber.org/atomic v1.11.0 // indirect
	golang.org/x/crypto v0.21.0 // indirect
	golang.org/x/exp/typeparams v0.0.0-20221208152030-732eee02a75a // indirect
	golang.org/x/mod v0.16.0 // indirect
	golang.org/x/sync v0.6.0 // indirect
	golang.org/x/sys v0.18.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	golang.org/x/time v0.5.0 // indirect
	golang.org/x/xerrors v0.0.0-20231012003039-104605ab7028 // indirect
	google.golang.org/api v0.169.0 // indirect
	google.golang.org/appengine v1.6.8 // indirect
	google.golang.org/genproto v0.0.0-20240311173647-c811ad7063a7 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20240311173647-c811ad7063a7 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20240311173647-c811ad7063a7 // indirect
	gopkg.in/DataDog/dd-trace-go.v1 v1.32.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

exclude (
	// CVE-2019-0205
	github.com/apache/thrift v0.12.0
	github.com/apache/thrift v0.13.0

	// CVE-2020-28483
	github.com/gin-gonic/gin v1.4.0
	github.com/gin-gonic/gin v1.6.3

	// CVE-2021-42576
	github.com/microcosm-cc/bluemonday v1.0.2
	github.com/nats-io/jwt v0.3.0

	// CVE-2020-26892
	github.com/nats-io/nats-server/v2 v2.1.2
)
