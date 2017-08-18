/* global __webpack_public_path__ */
import monacoContext from 'monaco-editor/dev/vs/loader';
import monacoLoader from '~/repo/monaco_loader';

describe('MonacoLoader', () => {
  it('calls require.config and exports require', () => {
    spyOn(monacoContext.require, 'config');

    const returnLoader = monacoLoader();

    expect(monacoContext.require.config).toHaveBeenCalledWith({
      paths: {
        vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
      },
    });
    expect(returnLoader).toBe(monacoContext.require);
  });
});
