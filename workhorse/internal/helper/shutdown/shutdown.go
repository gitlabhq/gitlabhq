/*
Package shutdown provides helper functions for graceful shutdowns
*/
package shutdown

import (
	"context"
	"errors"
	"sync"
)

// GracefulCloser is the interface implemented by types that can be shut down gracefully.
// The Shutdown method should stop accepting new work and complete or cancel any
// in-progress operations within the context's deadline. It should return an error
// if the shutdown process fails or if the context expires before shutdown completes.
type GracefulCloser interface {
	Shutdown(ctx context.Context) error
}

// ShutdownAll gracefully shuts down multiple GracefulCloser instances concurrently.
// It launches a goroutine for each closer and waits for all of them to complete or
// for the context to be canceled. All errors from the shutdown operations are collected
// and returned as a combined error.
//
// The function returns immediately if the closers slice is empty.
// If any closer returns an error, those errors are collected and joined together.
// The shutdown context's deadline applies to all closers collectively.
func ShutdownAll(ctx context.Context, closers ...GracefulCloser) error {
	if len(closers) == 0 {
		return nil
	}

	wg := &sync.WaitGroup{}
	errCh := make(chan error, len(closers))

	for _, c := range closers {
		wg.Add(1)

		go func(closer GracefulCloser) {
			defer wg.Done()

			if err := closer.Shutdown(ctx); err != nil {
				errCh <- err
			}
		}(c)
	}

	wg.Wait()
	close(errCh) // Close the channel after all goroutines are done

	var errs []error
	for err := range errCh {
		errs = append(errs, err)
	}

	return errors.Join(errs...)
}
