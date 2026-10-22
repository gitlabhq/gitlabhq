package duoworkflow

import (
	"context"
	"errors"
	"sync"
	"time"
)

var errActionPoolClosed = errors.New("action pool closed")

// actionPool runs the actions workhorse executes itself concurrently, at most
// size at a time. Duo Workflow Service matches responses to actions by request
// ID, so they may complete in any order.
type actionPool struct {
	sem    chan struct{}
	ctx    context.Context
	cancel context.CancelCauseFunc
	wg     sync.WaitGroup

	// mu makes starting a worker and closing the pool mutually exclusive, so
	// no worker starts once close is waiting for the others.
	mu sync.Mutex

	// errCh receives the first error that ends the run, such as a response
	// that could not be sent. Only one is sent, so it needs a single slot.
	errCh   chan<- error
	errOnce sync.Once
}

func newActionPool(ctx context.Context, size int, errCh chan<- error) *actionPool {
	ctx, cancel := context.WithCancelCause(ctx)

	return &actionPool{
		sem:    make(chan struct{}, size),
		ctx:    ctx,
		cancel: cancel,
		errCh:  errCh,
	}
}

// submit waits for a free worker and runs fn on it. While every worker is busy
// it blocks, which holds back the next Recv from Duo Workflow Service. It
// returns an error once the pool is canceled, and fn does not run.
func (p *actionPool) submit(actionType string, fn func(context.Context) error) error {
	start := time.Now()

	select {
	case p.sem <- struct{}{}:
	default:
		actionPoolSaturatedTotal.Inc()

		select {
		case p.sem <- struct{}{}:
		case <-p.ctx.Done():
			return context.Cause(p.ctx)
		}
	}

	p.mu.Lock()
	defer p.mu.Unlock()

	if err := context.Cause(p.ctx); err != nil {
		<-p.sem
		return err
	}

	actionQueueWaitSeconds.WithLabelValues(actionType).Observe(time.Since(start).Seconds())

	p.wg.Go(func() {
		defer func() { <-p.sem }()

		if err := fn(p.ctx); err != nil {
			p.fail(err)
		}
	})

	return nil
}

// fail reports err as the end of the run and cancels the actions still in
// flight, since their responses can no longer be delivered.
func (p *actionPool) fail(err error) {
	p.errOnce.Do(func() {
		p.cancel(err)
		p.errCh <- err
	})
}

// close cancels the actions still in flight and waits up to timeout for them
// to return, so none sends a response once the stream is closed. It reports
// whether they all did.
func (p *actionPool) close(timeout time.Duration) bool {
	if p == nil {
		return true
	}

	p.mu.Lock()
	p.cancel(errActionPoolClosed)
	p.mu.Unlock()

	done := make(chan struct{})
	go func() {
		p.wg.Wait()
		close(done)
	}()

	select {
	case <-done:
		return true
	case <-time.After(timeout):
		return false
	}
}
