import globalErrorHandler from '~/test_utils/global_error_handler';

describe('globalErrorHandler', () => {
  beforeEach(() => {
    spyOn(window, 'addEventListener');

    globalErrorHandler();
  });

  it('should bind console.error to the global error event', () => {
    expect(window.addEventListener).toHaveBeenCalledWith('error', console.error);
  });
});
