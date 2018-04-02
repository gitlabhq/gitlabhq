import Vue from 'vue';
import store from '~/ide/stores';
import service from '~/ide/services';
import router from '~/ide/ide_router';
import eventHub from '~/ide/eventhub';
import { file, resetStore } from '../../helpers';

describe('IDE store file actions', () => {
  beforeEach(() => {
    spyOn(router, 'push');
  });

  afterEach(() => {
    resetStore(store);
  });

  describe('closeFile', () => {
    let localFile;

    beforeEach(() => {
      localFile = file('testFile');
      localFile.active = true;
      localFile.opened = true;
      localFile.parentTreeUrl = 'parentTreeUrl';

      store.state.openFiles.push(localFile);
      store.state.entries[localFile.path] = localFile;
    });

    it('closes open files', done => {
      store
        .dispatch('closeFile', localFile.path)
        .then(() => {
          expect(localFile.opened).toBeFalsy();
          expect(localFile.active).toBeFalsy();
          expect(store.state.openFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });

    it('closes file even if file has changes', done => {
      store.state.changedFiles.push(localFile);

      store
        .dispatch('closeFile', localFile.path)
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('closes file & opens next available file', done => {
      const f = {
        ...file('newOpenFile'),
        url: '/newOpenFile',
      };

      store.state.openFiles.push(f);
      store.state.entries[f.path] = f;

      store
        .dispatch('closeFile', localFile.path)
        .then(Vue.nextTick)
        .then(() => {
          expect(router.push).toHaveBeenCalledWith(`/project${f.url}`);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('setFileActive', () => {
    let localFile;
    let scrollToTabSpy;
    let oldScrollToTab;

    beforeEach(() => {
      scrollToTabSpy = jasmine.createSpy('scrollToTab');
      oldScrollToTab = store._actions.scrollToTab; // eslint-disable-line
      store._actions.scrollToTab = [scrollToTabSpy]; // eslint-disable-line

      localFile = file('setThisActive');

      store.state.entries[localFile.path] = localFile;
    });

    afterEach(() => {
      store._actions.scrollToTab = oldScrollToTab; // eslint-disable-line
    });

    it('calls scrollToTab', done => {
      store
        .dispatch('setFileActive', localFile.path)
        .then(() => {
          expect(scrollToTabSpy).toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('sets the file active', done => {
      store
        .dispatch('setFileActive', localFile.path)
        .then(() => {
          expect(localFile.active).toBeTruthy();

          done();
        })
        .catch(done.fail);
    });

    it('returns early if file is already active', done => {
      localFile.active = true;

      store
        .dispatch('setFileActive', localFile.path)
        .then(() => {
          expect(scrollToTabSpy).not.toHaveBeenCalled();

          done();
        })
        .catch(done.fail);
    });

    it('sets current active file to not active', done => {
      const f = file('newActive');
      store.state.entries[f.path] = f;
      localFile.active = true;
      store.state.openFiles.push(localFile);

      store
        .dispatch('setFileActive', f.path)
        .then(() => {
          expect(localFile.active).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });

    it('resets location.hash for line highlighting', done => {
      location.hash = 'test';

      store
        .dispatch('setFileActive', localFile.path)
        .then(() => {
          expect(location.hash).not.toBe('test');

          done();
        })
        .catch(done.fail);
    });
  });

  describe('getFileData', () => {
    let localFile;

    beforeEach(() => {
      spyOn(service, 'getFileData').and.returnValue(
        Promise.resolve({
          headers: {
            'page-title': 'testing getFileData',
          },
          json: () =>
            Promise.resolve({
              blame_path: 'blame_path',
              commits_path: 'commits_path',
              permalink: 'permalink',
              raw_path: 'raw_path',
              binary: false,
              html: '123',
              render_error: '',
            }),
        }),
      );

      localFile = file(`newCreate-${Math.random()}`);
      localFile.url = 'getFileDataURL';
      store.state.entries[localFile.path] = localFile;
    });

    it('calls the service', done => {
      store
        .dispatch('getFileData', { path: localFile.path })
        .then(() => {
          expect(service.getFileData).toHaveBeenCalledWith('getFileDataURL');

          done();
        })
        .catch(done.fail);
    });

    it('sets the file data', done => {
      store
        .dispatch('getFileData', { path: localFile.path })
        .then(() => {
          expect(localFile.blamePath).toBe('blame_path');

          done();
        })
        .catch(done.fail);
    });

    it('sets document title', done => {
      store
        .dispatch('getFileData', { path: localFile.path })
        .then(() => {
          expect(document.title).toBe('testing getFileData');

          done();
        })
        .catch(done.fail);
    });

    it('sets the file as active', done => {
      store
        .dispatch('getFileData', { path: localFile.path })
        .then(() => {
          expect(localFile.active).toBeTruthy();

          done();
        })
        .catch(done.fail);
    });

    it('sets the file not as active if we pass makeFileActive false', done => {
      store
        .dispatch('getFileData', { path: localFile.path, makeFileActive: false })
        .then(() => {
          expect(localFile.active).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });

    it('adds the file to open files', done => {
      store
        .dispatch('getFileData', { path: localFile.path })
        .then(() => {
          expect(store.state.openFiles.length).toBe(1);
          expect(store.state.openFiles[0].name).toBe(localFile.name);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('getRawFileData', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(service, 'getRawFileData').and.returnValue(Promise.resolve('raw'));

      tmpFile = file('tmpFile');
      store.state.entries[tmpFile.path] = tmpFile;
    });

    it('calls getRawFileData service method', done => {
      store
        .dispatch('getRawFileData', { path: tmpFile.path })
        .then(() => {
          expect(service.getRawFileData).toHaveBeenCalledWith(tmpFile);

          done();
        })
        .catch(done.fail);
    });

    it('updates file raw data', done => {
      store
        .dispatch('getRawFileData', { path: tmpFile.path })
        .then(() => {
          expect(tmpFile.raw).toBe('raw');

          done();
        })
        .catch(done.fail);
    });

    it('calls also getBaseRawFileData service method', done => {
      spyOn(service, 'getBaseRawFileData').and.returnValue(Promise.resolve('baseraw'));

      tmpFile.mrChange = { new_file: false };

      store
        .dispatch('getRawFileData', { path: tmpFile.path, baseSha: 'SHA' })
        .then(() => {
          expect(service.getBaseRawFileData).toHaveBeenCalledWith(tmpFile, 'SHA');
          expect(tmpFile.baseRaw).toBe('baseraw');

          done();
        })
        .catch(done.fail);
    });
  });

  describe('changeFileContent', () => {
    let tmpFile;

    beforeEach(() => {
      tmpFile = file('tmpFile');
      store.state.entries[tmpFile.path] = tmpFile;
    });

    it('updates file content', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() => {
          expect(tmpFile.content).toBe('content');

          done();
        })
        .catch(done.fail);
    });

    it('adds file into changedFiles array', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() => {
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('adds file once into changedFiles array', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() =>
          store.dispatch('changeFileContent', {
            path: tmpFile.path,
            content: 'content 123',
          }),
        )
        .then(() => {
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('removes file from changedFiles array if not changed', done => {
      store
        .dispatch('changeFileContent', {
          path: tmpFile.path,
          content: 'content',
        })
        .then(() =>
          store.dispatch('changeFileContent', {
            path: tmpFile.path,
            content: '',
          }),
        )
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });
  });

  describe('discardFileChanges', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(eventHub, '$on');

      tmpFile = file();
      tmpFile.content = 'testing';

      store.state.changedFiles.push(tmpFile);
      store.state.entries[tmpFile.path] = tmpFile;
    });

    it('resets file content', done => {
      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.content).not.toBe('testing');

          done();
        })
        .catch(done.fail);
    });

    it('removes file from changedFiles array', done => {
      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(store.state.changedFiles.length).toBe(0);

          done();
        })
        .catch(done.fail);
    });

    it('closes temp file', done => {
      tmpFile.tempFile = true;
      tmpFile.opened = true;

      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.opened).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });

    it('does not re-open a closed temp file', done => {
      tmpFile.tempFile = true;

      expect(tmpFile.opened).toBeFalsy();

      store
        .dispatch('discardFileChanges', tmpFile.path)
        .then(() => {
          expect(tmpFile.opened).toBeFalsy();

          done();
        })
        .catch(done.fail);
    });
  });
});
