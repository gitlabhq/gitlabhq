import monacoContext from 'monaco-editor/dev/vs/loader';
import monacoLoader from 'ee/ide/monaco_loader';

describe('MonacoLoader', () => {
  it('calls require.config and exports require', () => {
    expect(monacoContext.require.getConfig()).toEqual(jasmine.objectContaining({
      paths: {
        vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
      },
    }));
    expect(monacoLoader).toBe(monacoContext.require);
  });
});
