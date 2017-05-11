import globalErrorHandler, { errorHandler } from '~/test_utils/global_error_handler';

describe('globalErrorHandler', () => {
  beforeEach(() => {
    spyOn(window, 'addEventListener');

    globalErrorHandler();
  });

  it('should bind a function to the global error event', () => {
    expect(window.addEventListener).toHaveBeenCalledWith('error', errorHandler);
  });
});

describe('errorHandler', () => {
  beforeEach(() => {
    spyOn(console, 'error');

    errorHandler();
  });

  it('should call console.error', () => {
    expect(console.error).toHaveBeenCalled();
  });
});
