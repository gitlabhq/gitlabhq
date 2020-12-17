package objectstore

import (
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

var (
	objectStorageUploadRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_object_storage_upload_requests",
			Help: "How many object storage requests have been processed",
		},
		[]string{"status"},
	)
	objectStorageUploadsOpen = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "gitlab_workhorse_object_storage_upload_open",
			Help: "Describes many object storage requests are open now",
		},
	)
	objectStorageUploadBytes = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_object_storage_upload_bytes",
			Help: "How many bytes were sent to object storage",
		},
	)
	objectStorageUploadTime = promauto.NewHistogram(
		prometheus.HistogramOpts{
			Name:    "gitlab_workhorse_object_storage_upload_time",
			Help:    "How long it took to upload objects",
			Buckets: objectStorageUploadTimeBuckets,
		})

	objectStorageUploadRequestsRequestFailed = objectStorageUploadRequests.WithLabelValues("request-failed")
	objectStorageUploadRequestsInvalidStatus = objectStorageUploadRequests.WithLabelValues("invalid-status")

	objectStorageUploadTimeBuckets = []float64{.1, .25, .5, 1, 2.5, 5, 10, 25, 50, 100}
)
