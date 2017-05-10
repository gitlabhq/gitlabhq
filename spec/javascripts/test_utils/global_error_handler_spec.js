import globalErrorHandler from '~/test_utils/global_error_handler';

describe('globalErrorHandler', () => {
  beforeEach(() => {
    spyOn(window, 'addEventListener');

    globalErrorHandler();
  });

  it('should bind console.log to the global error event', () => {
    expect(window.addEventListener).toHaveBeenCalledWith('error', console.log);
  });
});
