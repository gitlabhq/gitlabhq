import mutations from 'ee/ide/stores/mutations/file';
import state from 'ee/ide/stores/state';
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
          html: 'html',
          render_error: 'render_error',
        },
        file: localFile,
      });

      expect(localFile.blamePath).toBe('blame');
      expect(localFile.commitsPath).toBe('commits');
      expect(localFile.permalink).toBe('permalink');
      expect(localFile.rawPath).toBe('raw');
      expect(localFile.binary).toBeTruthy();
      expect(localFile.html).toBe('html');
      expect(localFile.renderError).toBe('render_error');
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

    it('sets changed if file is a temp file', () => {
      localFile.tempFile = true;

      mutations.UPDATE_FILE_CONTENT(localState, {
        file: localFile,
        content: '',
      });

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
      const f = file('tmpFile');

      mutations.CREATE_TMP_FILE(localState, {
        file: f,
        parent: localFile,
      });

      expect(localFile.tree.length).toBe(1);
      expect(localFile.tree[0].name).toBe(f.name);
    });
  });

  describe('ADD_FILE_TO_CHANGED', () => {
    it('adds file into changed files array', () => {
      const f = file();

      mutations.ADD_FILE_TO_CHANGED(localState, f);

      expect(localState.changedFiles.length).toBe(1);
    });
  });

  describe('REMOVE_FILE_FROM_CHANGED', () => {
    it('removes files from changed files array', () => {
      const f = file();

      localState.changedFiles.push(f);

      mutations.REMOVE_FILE_FROM_CHANGED(localState, f);

      expect(localState.changedFiles.length).toBe(0);
    });
  });
});
