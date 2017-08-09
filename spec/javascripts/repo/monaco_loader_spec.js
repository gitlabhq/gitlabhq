/* global __webpack_public_path__ */
import monacoContext from 'monaco-editor/dev/vs/loader';

describe('MonacoLoader', () => {
  it('calls require.config and exports require', () => {
    spyOn(monacoContext.require, 'config');

    const monacoLoader = require('~/repo/monaco_loader'); // eslint-disable-line global-require

    expect(monacoContext.require.config).toHaveBeenCalledWith({
      paths: {
        vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
      },
    });
    expect(monacoLoader.default).toBe(monacoContext.require);
  });
});
