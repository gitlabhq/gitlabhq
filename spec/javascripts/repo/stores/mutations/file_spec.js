import mutations from '~/repo/stores/mutations/file';
import state from '~/repo/stores/state';
import { file } from '../../helpers';

describe('Multi-file store file mutations', () => {
  let localState;
  let localFile;

  beforeEach(() => {
    localState = state();
    localFile = file();
  });

  describe('SET_FILE_ACTIVE', () => {
    it('sets the file active', () => {
      mutations.SET_FILE_ACTIVE(localState, {
        file: localFile,
        active: true,
      });

      expect(localFile.active).toBeTruthy();
    });
  });

  describe('TOGGLE_FILE_OPEN', () => {
    beforeEach(() => {
      mutations.TOGGLE_FILE_OPEN(localState, localFile);
    });

    it('adds into opened files', () => {
      expect(localFile.opened).toBeTruthy();
      expect(localState.openFiles.length).toBe(1);
    });

    it('removes from opened files', () => {
      mutations.TOGGLE_FILE_OPEN(localState, localFile);

      expect(localFile.opened).toBeFalsy();
      expect(localState.openFiles.length).toBe(0);
    });
  });

  describe('SET_FILE_DATA', () => {
    it('sets extra file data', () => {
      mutations.SET_FILE_DATA(localState, {
        data: {
          blame_path: 'blame',
          commits_path: 'commits',
          permalink: 'permalink',
          raw_path: 'raw',
          binary: true,
          render_error: 'render_error',
        },
        file: localFile,
      });

      expect(localFile.blamePath).toBe('blame');
      expect(localFile.commitsPath).toBe('commits');
      expect(localFile.permalink).toBe('permalink');
      expect(localFile.rawPath).toBe('raw');
      expect(localFile.binary).toBeTruthy();
      expect(localFile.renderError).toBe('render_error');
    });

    it('sets rich viewer data', () => {
      mutations.SET_FILE_DATA(localState, {
        data: {
          blame_path: 'blame',
          commits_path: 'commits',
          permalink: 'permalink',
          raw_path: 'raw',
          binary: true,
          render_error: 'render_error',
          rich_viewer: {
            path: 'richPath',
            switcher_icon: 'richIcon',
          },
        },
        file: localFile,
      });

      expect(localFile.rich.path).toBe('richPath');
      expect(localFile.rich.icon).toBe('richIcon');
    });

    it('sets simple viewer data', () => {
      mutations.SET_FILE_DATA(localState, {
        data: {
          blame_path: 'blame',
          commits_path: 'commits',
          permalink: 'permalink',
          raw_path: 'raw',
          binary: true,
          render_error: 'render_error',
          simple_viewer: {
            path: 'simplePath',
            switcher_icon: 'simpleIcon',
          },
        },
        file: localFile,
      });

      expect(localFile.simple.path).toBe('simplePath');
      expect(localFile.simple.icon).toBe('simpleIcon');
    });
  });

  describe('SET_FILE_RAW_DATA', () => {
    it('sets raw data', () => {
      mutations.SET_FILE_RAW_DATA(localState, {
        file: localFile,
        raw: 'testing',
      });

      expect(localFile.raw).toBe('testing');
    });
  });

  describe('UPDATE_FILE_CONTENT', () => {
    beforeEach(() => {
      localFile.raw = 'test';
    });

    it('sets content', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        file: localFile,
        content: 'test',
      });

      expect(localFile.content).toBe('test');
    });

    it('sets changed if content does not match raw', () => {
      mutations.UPDATE_FILE_CONTENT(localState, {
        file: localFile,
        content: 'testing',
      });

      expect(localFile.content).toBe('testing');
      expect(localFile.changed).toBeTruthy();
    });
  });

  describe('DISCARD_FILE_CHANGES', () => {
    beforeEach(() => {
      localFile.content = 'test';
      localFile.changed = true;
    });

    it('resets content and changed', () => {
      mutations.DISCARD_FILE_CHANGES(localState, localFile);

      expect(localFile.content).toBe('');
      expect(localFile.changed).toBeFalsy();
    });
  });

  describe('CREATE_TMP_FILE', () => {
    it('adds file into parent tree', () => {
      const f = file();

      mutations.CREATE_TMP_FILE(localState, {
        file: f,
        parent: localFile,
      });

      expect(localFile.tree.length).toBe(1);
      expect(localFile.tree[0].name).toBe(f.name);
    });
  });

  describe('SET_FILE_VIEWER_DATA', () => {
    describe('rich viewer', () => {
      it('sets current viewers HTML', () => {
        const f = file();

        mutations.SET_FILE_VIEWER_DATA(localState, {
          file: f,
          data: { html: 'fileHTML' },
        });

        expect(f.rich.html).toBe('fileHTML');
      });
    });

    describe('simple viewer', () => {
      it('sets current viewers HTML', () => {
        const f = file();
        f.currentViewer = 'simple';

        mutations.SET_FILE_VIEWER_DATA(localState, {
          file: f,
          data: { html: 'fileHTML' },
        });

        expect(f.simple.html).toBe('fileHTML');
      });
    });
  });

  describe('SET_CURRENT_FILE_VIEWER', () => {
    it('sets the files current viewer', () => {
      const f = file();

      mutations.SET_CURRENT_FILE_VIEWER(localState, {
        file: f,
        type: 'rich',
      });

      expect(f.currentViewer).toBe('rich');
    });
  });

  describe('TOGGLE_FILE_VIEWER_LOADING', () => {
    it('toggles viewer loading', () => {
      const f = file();

      mutations.TOGGLE_FILE_VIEWER_LOADING(localState, f.rich);

      expect(f.rich.loading).toBeTruthy();

      mutations.TOGGLE_FILE_VIEWER_LOADING(localState, f.rich);

      expect(f.rich.loading).toBeFalsy();
    });
  });

  describe('RESET_VIEWER_RENDER_ERROR', () => {
    it('resets render error and render error reason', () => {
      const f = file();
      Object.assign(f.rich, {
        renderError: 'error',
        renderErrorReason: 'error',
      });

      mutations.RESET_VIEWER_RENDER_ERROR(localState, f.rich);

      expect(f.rich.renderError).toBe('');
      expect(f.rich.renderErrorReason).toBe('');
    });
  });
});
