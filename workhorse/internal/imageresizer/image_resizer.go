package imageresizer

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	"strings"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type Resizer struct {
	config.Config
	senddata.Prefix
	numScalerProcs processCounter
}

type resizeParams struct {
	Location    string
	ContentType string
	Width       uint
}

type processCounter struct {
	n int32
}

type resizeStatus = string

type imageFile struct {
	reader        io.ReadCloser
	contentLength int64
	lastModified  time.Time
}

// Carries information about how the scaler succeeded or failed.
type resizeOutcome struct {
	bytesWritten     int64
	originalFileSize int64
	status           resizeStatus
	err              error
}

const (
	statusSuccess        = "success"              // a rescaled image was served
	statusClientCache    = "success-client-cache" // scaling was skipped because client cache was fresh
	statusServedOriginal = "served-original"      // scaling failed but the original image was served
	statusRequestFailure = "request-failed"       // no image was served
	statusUnknown        = "unknown"              // indicates an unhandled status case
)

var envInjector = tracing.NewEnvInjector()

// Images might be located remotely in object storage, in which case we need to stream
// it via http(s)
var httpTransport = tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
	Proxy: http.ProxyFromEnvironment,
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 10 * time.Second,
	}).DialContext,
	MaxIdleConns:          2,
	IdleConnTimeout:       30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
}))

var httpClient = &http.Client{
	Transport: httpTransport,
}

const (
	namespace = "gitlab_workhorse"
	subsystem = "image_resize"
	logSystem = "imageresizer"
)

var (
	imageResizeConcurrencyLimitExceeds = promauto.NewCounter(
		prometheus.CounterOpts{
			Namespace: namespace,
			Subsystem: subsystem,
			Name:      "concurrency_limit_exceeds_total",
			Help:      "Amount of image resizing requests that exceeded the maximum allowed scaler processes",
		},
	)
	imageResizeProcesses = promauto.NewGauge(
		prometheus.GaugeOpts{
			Namespace: namespace,
			Subsystem: subsystem,
			Name:      "processes",
			Help:      "Amount of image scaler processes working now",
		},
	)
	imageResizeMaxProcesses = promauto.NewGauge(
		prometheus.GaugeOpts{
			Namespace: namespace,
			Subsystem: subsystem,
			Name:      "max_processes",
			Help:      "The maximum amount of image scaler processes allowed to run concurrently",
		},
	)
	imageResizeRequests = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Namespace: namespace,
			Subsystem: subsystem,
			Name:      "requests_total",
			Help:      "Image resizing operations requested",
		},
		[]string{"status"},
	)
	imageResizeDurations = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Namespace: namespace,
			Subsystem: subsystem,
			Name:      "duration_seconds",
			Help:      "Breakdown of total time spent serving successful image resizing requests (incl. data transfer)",
			Buckets: []float64{
				0.025, /* 25ms */
				0.050, /* 50ms */
				0.1,   /* 100ms */
				0.2,   /* 200ms */
				0.4,   /* 400ms */
				0.8,   /* 800ms */
			},
		},
		[]string{"content_type", "width"},
	)
)

const (
	jpegMagic   = "\xff\xd8"          // 2 bytes
	pngMagic    = "\x89PNG\r\n\x1a\n" // 8 bytes
	maxMagicLen = 8                   // 8 first bytes is enough to detect PNG or JPEG
)

func NewResizer(cfg config.Config) *Resizer {
	imageResizeMaxProcesses.Set(float64(cfg.ImageResizerConfig.MaxScalerProcs))

	return &Resizer{Config: cfg, Prefix: "send-scaled-img:"}
}

// Inject forks into a dedicated scaler process to resize an image identified by path or URL
// and streams the resized image back to the client
func (r *Resizer) Inject(w http.ResponseWriter, req *http.Request, paramsData string) {
	var outcome = resizeOutcome{status: statusUnknown, originalFileSize: 0, bytesWritten: 0}
	start := time.Now()
	params, err := r.unpackParameters(paramsData)

	defer func() {
		imageResizeRequests.WithLabelValues(outcome.status).Inc()
		handleOutcome(w, req, start, params, &outcome)
	}()

	if err != nil {
		// This means the response header coming from Rails was malformed; there is no way
		// to sensibly recover from this other than failing fast
		outcome.error(fmt.Errorf("read image resize params: %v", err))
		return
	}

	imageFile, err := openSourceImage(params.Location)
	if err != nil {
		// This means we cannot even read the input image; fail fast.
		outcome.error(fmt.Errorf("open image data stream: %v", err))
		return
	}
	defer imageFile.reader.Close()

	outcome.originalFileSize = imageFile.contentLength

	setLastModified(w, imageFile.lastModified)
	// If the original file has not changed, then any cached resized versions have not changed either.
	if checkNotModified(req, imageFile.lastModified) {
		writeNotModified(w)
		outcome.ok(statusClientCache)
		return
	}

	// We first attempt to rescale the image; if this should fail for any reason, imageReader
	// will point to the original image, i.e. we render it unchanged.
	imageReader, resizeCmd, err := r.tryResizeImage(req, imageFile, params, r.Config.ImageResizerConfig)
	if err != nil {
		// Something failed, but we can still write out the original image, so don't return early.
		// We need to log this separately since the subsequent steps might add other failures.
		log.WithRequest(req).WithFields(logFields(start, params, &outcome)).WithError(err).Error()
	}
	defer helper.CleanUpProcessGroup(resizeCmd)

	w.Header().Del("Content-Length")
	outcome.bytesWritten, err = serveImage(imageReader, w, resizeCmd)

	// We failed serving image data; this is a hard failure.
	if err != nil {
		outcome.error(err)
		return
	}

	// This means we served the original image because rescaling failed; this is a soft failure
	if resizeCmd == nil {
		outcome.ok(statusServedOriginal)
		return
	}

	widthLabelVal := strconv.Itoa(int(params.Width))
	imageResizeDurations.WithLabelValues(params.ContentType, widthLabelVal).Observe(time.Since(start).Seconds())

	outcome.ok(statusSuccess)
}

// Streams image data from the given reader to the given writer and returns the number of bytes written.
func serveImage(r io.Reader, w io.Writer, resizeCmd *exec.Cmd) (int64, error) {
	bytesWritten, err := io.Copy(w, r)
	if err != nil {
		return bytesWritten, err
	}

	if resizeCmd != nil {
		// If a scaler process had been forked, wait for the command to finish.
		if err = resizeCmd.Wait(); err != nil {
			// err will be an ExitError; this is not useful beyond knowing the exit code since anything
			// interesting has been written to stderr, so we turn that into an error we can return.
			stdErr := resizeCmd.Stderr.(*strings.Builder)
			return bytesWritten, fmt.Errorf(stdErr.String())
		}
	}

	return bytesWritten, nil
}

func (r *Resizer) unpackParameters(paramsData string) (*resizeParams, error) {
	var params resizeParams
	if err := r.Unpack(&params, paramsData); err != nil {
		return nil, err
	}

	if params.Location == "" {
		return nil, fmt.Errorf("'Location' not set")
	}

	if params.ContentType == "" {
		return nil, fmt.Errorf("'ContentType' must be set")
	}

	return &params, nil
}

// Attempts to rescale the given image data, or in case of errors, falls back to the original image.
func (r *Resizer) tryResizeImage(req *http.Request, f *imageFile, params *resizeParams, cfg config.ImageResizerConfig) (io.Reader, *exec.Cmd, error) {
	if f.contentLength > int64(cfg.MaxFilesize) {
		return f.reader, nil, fmt.Errorf("%d bytes exceeds maximum file size of %d bytes", f.contentLength, cfg.MaxFilesize)
	}

	if f.contentLength < maxMagicLen {
		return f.reader, nil, fmt.Errorf("file is too small to resize: %d bytes", f.contentLength)
	}

	if !r.numScalerProcs.tryIncrement(int32(cfg.MaxScalerProcs)) {
		return f.reader, nil, fmt.Errorf("too many running scaler processes (%d / %d)", r.numScalerProcs.n, cfg.MaxScalerProcs)
	}

	ctx := req.Context()
	go func() {
		<-ctx.Done()
		r.numScalerProcs.decrement()
	}()

	// Creating buffered Reader is required for us to Peek into first bytes of the image file to detect the format
	// without advancing the reader (we need to read from the file start in the Scaler binary).
	// We set `8` as the minimal buffer size by the length of PNG magic bytes sequence (JPEG needs only 2).
	// In fact, `NewReaderSize` will immediately override it with `16` using its `minReadBufferSize` -
	// here we are just being explicit about the buffer size required for our code to operate correctly.
	// Having a reader with such tiny buffer will not hurt the performance during further operations,
	// because Golang `bufio.Read` avoids double copy: https://golang.org/src/bufio/bufio.go?s=1768:1804#L212
	buffered := bufio.NewReaderSize(f.reader, maxMagicLen)

	headerBytes, err := buffered.Peek(maxMagicLen)
	if err != nil {
		return buffered, nil, fmt.Errorf("peek stream: %v", err)
	}

	// Check magic bytes to identify file type.
	if string(headerBytes) != pngMagic && string(headerBytes[0:2]) != jpegMagic {
		return buffered, nil, fmt.Errorf("unrecognized file signature: %v", headerBytes)
	}

	resizeCmd, resizedImageReader, err := startResizeImageCommand(ctx, buffered, params)
	if err != nil {
		return buffered, nil, fmt.Errorf("fork into scaler process: %w", err)
	}
	return resizedImageReader, resizeCmd, nil
}

func startResizeImageCommand(ctx context.Context, imageReader io.Reader, params *resizeParams) (*exec.Cmd, io.ReadCloser, error) {
	cmd := exec.CommandContext(ctx, "gitlab-resize-image")
	cmd.Stdin = imageReader
	cmd.Stderr = &strings.Builder{}
	cmd.SysProcAttr = &syscall.SysProcAttr{Setpgid: true}
	cmd.Env = []string{
		"GL_RESIZE_IMAGE_WIDTH=" + strconv.Itoa(int(params.Width)),
	}
	cmd.Env = envInjector(ctx, cmd.Env)

	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return nil, nil, err
	}

	if err := cmd.Start(); err != nil {
		return nil, nil, err
	}

	return cmd, stdout, nil
}

func isURL(location string) bool {
	return strings.HasPrefix(location, "http://") || strings.HasPrefix(location, "https://")
}

func openSourceImage(location string) (*imageFile, error) {
	if isURL(location) {
		return openFromURL(location)
	}

	return openFromFile(location)
}

func openFromURL(location string) (*imageFile, error) {
	res, err := httpClient.Get(location)
	if err != nil {
		return nil, err
	}

	switch res.StatusCode {
	case http.StatusOK, http.StatusNotModified:
		// Extract headers for conditional GETs from response.
		lastModified, err := http.ParseTime(res.Header.Get("Last-Modified"))
		if err != nil {
			// This is unlikely to happen, coming from an object storage provider.
			lastModified = time.Now().UTC()
		}
		return &imageFile{res.Body, res.ContentLength, lastModified}, nil
	default:
		res.Body.Close()
		return nil, fmt.Errorf("stream data from %q: %d %s", location, res.StatusCode, res.Status)
	}
}

func openFromFile(location string) (*imageFile, error) {
	file, err := os.Open(location)
	if err != nil {
		return nil, err
	}

	fi, err := file.Stat()
	if err != nil {
		file.Close()
		return nil, err
	}

	return &imageFile{file, fi.Size(), fi.ModTime()}, nil
}

// Only allow more scaling requests if we haven't yet reached the maximum
// allowed number of concurrent scaler processes
func (c *processCounter) tryIncrement(maxScalerProcs int32) bool {
	if p := atomic.AddInt32(&c.n, 1); p > maxScalerProcs {
		c.decrement()
		imageResizeConcurrencyLimitExceeds.Inc()

		return false
	}

	imageResizeProcesses.Set(float64(c.n))
	return true
}

func (c *processCounter) decrement() {
	atomic.AddInt32(&c.n, -1)
	imageResizeProcesses.Set(float64(c.n))
}

func (o *resizeOutcome) ok(status resizeStatus) {
	o.status = status
	o.err = nil
}

func (o *resizeOutcome) error(err error) {
	o.status = statusRequestFailure
	o.err = err
}

func logFields(startTime time.Time, params *resizeParams, outcome *resizeOutcome) log.Fields {
	var targetWidth, contentType string
	if params != nil {
		targetWidth = fmt.Sprint(params.Width)
		contentType = fmt.Sprint(params.ContentType)
	}
	return log.Fields{
		"subsystem":                      logSystem,
		"written_bytes":                  outcome.bytesWritten,
		"duration_s":                     time.Since(startTime).Seconds(),
		logSystem + ".status":            outcome.status,
		logSystem + ".target_width":      targetWidth,
		logSystem + ".content_type":      contentType,
		logSystem + ".original_filesize": outcome.originalFileSize,
	}
}

func handleOutcome(w http.ResponseWriter, req *http.Request, startTime time.Time, params *resizeParams, outcome *resizeOutcome) {
	fields := logFields(startTime, params, outcome)
	log := log.WithRequest(req).WithFields(fields)

	switch outcome.status {
	case statusRequestFailure:
		if outcome.bytesWritten <= 0 {
			helper.Fail500WithFields(w, req, outcome.err, fields)
		} else {
			log.WithError(outcome.err).Error(outcome.status)
		}
	default:
		log.Info(outcome.status)
	}
}
