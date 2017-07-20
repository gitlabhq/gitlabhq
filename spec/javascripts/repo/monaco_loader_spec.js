describe('MonacoLoader', () => {
  it('sets __monaco_context__', () => {
    const monacoContext = require('monaco-editor/dev/vs/loader'); // eslint-disable-line global-require

    expect(window.__monaco_context__) // eslint-disable-line no-underscore-dangle
      .toBe(monacoContext);
  });
});
