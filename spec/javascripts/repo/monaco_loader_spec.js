import monacoContext from 'monaco-editor/dev/vs/loader';
import monacoLoader from '~/repo/monaco_loader';

describe('MonacoLoader', () => {
  it('calls require.config and exports require', () => {
    const loader = monacoLoader();

    expect(monacoContext.require.getConfig()).toEqual(jasmine.objectContaining({
      paths: {
        vs: `${__webpack_public_path__}monaco-editor/vs`, // eslint-disable-line camelcase
      },
    }));
    expect(loader).toBe(monacoContext.require);
  });
});
