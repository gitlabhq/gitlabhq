import Vue from 'vue';
import store from '~/repo/stores';
import service from '~/repo/services';
import { file, resetStore } from '../../helpers';

describe('Multi-file store file actions', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('closeFile', () => {
    let localFile;
    let getLastCommitDataSpy;
    let oldGetLastCommitData;

    beforeEach(() => {
      getLastCommitDataSpy = jasmine.createSpy('getLastCommitData');
      oldGetLastCommitData = store._actions.getLastCommitData; // eslint-disable-line
      store._actions.getLastCommitData = [getLastCommitDataSpy]; // eslint-disable-line

      localFile = file();
      localFile.active = true;
      localFile.opened = true;
      localFile.parentTreeUrl = 'parentTreeUrl';

      store.state.openFiles.push(localFile);

      spyOn(history, 'pushState');
    });

    afterEach(() => {
      store._actions.getLastCommitData = oldGetLastCommitData; // eslint-disable-line
    });

    it('closes open files', (done) => {
      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(localFile.opened).toBeFalsy();
          expect(localFile.active).toBeFalsy();
          expect(store.state.openFiles.length).toBe(0);

          done();
        }).catch(done.fail);
    });

    it('does not close file if has changed', (done) => {
      localFile.changed = true;

      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(localFile.opened).toBeTruthy();
          expect(localFile.active).toBeTruthy();
          expect(store.state.openFiles.length).toBe(1);

          done();
        }).catch(done.fail);
    });

    it('does not close file if temp file', (done) => {
      localFile.tempFile = true;

      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(localFile.opened).toBeTruthy();
          expect(localFile.active).toBeTruthy();
          expect(store.state.openFiles.length).toBe(1);

          done();
        }).catch(done.fail);
    });

    it('force closes a changed file', (done) => {
      localFile.changed = true;

      store.dispatch('closeFile', { file: localFile, force: true })
        .then(() => {
          expect(localFile.opened).toBeFalsy();
          expect(localFile.active).toBeFalsy();
          expect(store.state.openFiles.length).toBe(0);

          done();
        }).catch(done.fail);
    });

    it('calls pushState when no open files are left', (done) => {
      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(history.pushState).toHaveBeenCalledWith(jasmine.anything(), '', 'parentTreeUrl');

          done();
        }).catch(done.fail);
    });

    it('sets next file as active', (done) => {
      const f = file();
      store.state.openFiles.push(f);

      expect(f.active).toBeFalsy();

      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(f.active).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('calls getLastCommitData', (done) => {
      store.dispatch('closeFile', { file: localFile })
        .then(() => {
          expect(getLastCommitDataSpy).toHaveBeenCalled();

          done();
        }).catch(done.fail);
    });
  });

  describe('setFileActive', () => {
    let scrollToTabSpy;
    let oldScrollToTab;

    beforeEach(() => {
      scrollToTabSpy = jasmine.createSpy('scrollToTab');
      oldScrollToTab = store._actions.scrollToTab; // eslint-disable-line
      store._actions.scrollToTab = [scrollToTabSpy]; // eslint-disable-line
    });

    afterEach(() => {
      store._actions.scrollToTab = oldScrollToTab; // eslint-disable-line
    });

    it('calls scrollToTab', (done) => {
      store.dispatch('setFileActive', file())
        .then(() => {
          expect(scrollToTabSpy).toHaveBeenCalled();

          done();
        }).catch(done.fail);
    });

    it('sets the file active', (done) => {
      const localFile = file();

      store.dispatch('setFileActive', localFile)
        .then(() => {
          expect(localFile.active).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('returns early if file is already active', (done) => {
      const localFile = file();
      localFile.active = true;

      store.dispatch('setFileActive', localFile)
        .then(() => {
          expect(scrollToTabSpy).not.toHaveBeenCalled();

          done();
        }).catch(done.fail);
    });

    it('sets current active file to not active', (done) => {
      const localFile = file();
      localFile.active = true;
      store.state.openFiles.push(localFile);

      store.dispatch('setFileActive', file())
        .then(() => {
          expect(localFile.active).toBeFalsy();

          done();
        }).catch(done.fail);
    });

    it('resets location.hash for line highlighting', (done) => {
      location.hash = 'test';

      store.dispatch('setFileActive', file())
        .then(() => {
          expect(location.hash).not.toBe('test');

          done();
        }).catch(done.fail);
    });
  });

  describe('getFileData', () => {
    let localFile = file();

    beforeEach(() => {
      spyOn(history, 'pushState');
      spyOn(service, 'getFileData').and.returnValue(Promise.resolve({
        headers: {
          'page-title': 'testing getFileData',
        },
        json: () => Promise.resolve({
          blame_path: 'blame_path',
          commits_path: 'commits_path',
          permalink: 'permalink',
          raw_path: 'raw_path',
          binary: false,
          render_error: '',
        }),
      }));

      localFile = file();
      localFile.url = 'getFileDataURL';
    });

    it('calls the service', (done) => {
      store.dispatch('getFileData', localFile)
        .then(() => {
          expect(service.getFileData).toHaveBeenCalledWith('getFileDataURL');

          done();
        }).catch(done.fail);
    });

    it('sets the file data', (done) => {
      store.dispatch('getFileData', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(localFile.blamePath).toBe('blame_path');

          done();
        }).catch(done.fail);
    });

    it('sets document title', (done) => {
      store.dispatch('getFileData', localFile)
        .then(() => {
          expect(document.title).toBe('testing getFileData');

          done();
        }).catch(done.fail);
    });

    it('sets the file as active', (done) => {
      store.dispatch('getFileData', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(localFile.active).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('adds the file to open files', (done) => {
      store.dispatch('getFileData', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.openFiles.length).toBe(1);
          expect(store.state.openFiles[0].name).toBe(localFile.name);

          done();
        }).catch(done.fail);
    });

    it('toggles the file loading', (done) => {
      store.dispatch('getFileData', localFile)
        .then(() => {
          expect(localFile.loading).toBeTruthy();

          return Vue.nextTick();
        })
        .then(() => {
          expect(localFile.loading).toBeFalsy();

          done();
        }).catch(done.fail);
    });

    it('calls getFileHTML with current active file', (done) => {
      const oldGetFileHTML = store._actions.getFileHTML; // eslint-disable-line
      const getFileHTMLSpy = jasmine.createSpy('getFileHTML');
      store._actions.getFileHTML = [getFileHTMLSpy]; // eslint-disable-line

      store.dispatch('getFileData', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(getFileHTMLSpy).toHaveBeenCalledWith({ file: localFile });

          store._actions.getFileHTML = oldGetFileHTML; // eslint-disable-line

          done();
        }).catch(done.fail);
    });
  });

  describe('getRawFileData', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(service, 'getRawFileData').and.returnValue(Promise.resolve('raw'));

      tmpFile = file();
    });

    it('calls getRawFileData service method', (done) => {
      store.dispatch('getRawFileData', tmpFile)
        .then(() => {
          expect(service.getRawFileData).toHaveBeenCalledWith(tmpFile);

          done();
        }).catch(done.fail);
    });

    it('updates file raw data', (done) => {
      store.dispatch('getRawFileData', tmpFile)
        .then(() => {
          expect(tmpFile.raw).toBe('raw');

          done();
        }).catch(done.fail);
    });
  });

  describe('changeFileContent', () => {
    let tmpFile;

    beforeEach(() => {
      tmpFile = file();
    });

    it('updates file content', (done) => {
      store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content',
      })
      .then(() => {
        expect(tmpFile.content).toBe('content');

        done();
      }).catch(done.fail);
    });
  });

  describe('createTempFile', () => {
    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"></div>';
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    it('creates temp file', (done) => {
      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then((f) => {
        expect(f.tempFile).toBeTruthy();
        expect(store.state.tree.length).toBe(1);

        done();
      }).catch(done.fail);
    });

    it('adds tmp file to open files', (done) => {
      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then((f) => {
        expect(store.state.openFiles.length).toBe(1);
        expect(store.state.openFiles[0].name).toBe(f.name);

        done();
      }).catch(done.fail);
    });

    it('sets tmp file as active', (done) => {
      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then((f) => {
        expect(f.active).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('enters edit mode if file is not binary', (done) => {
      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then(() => {
        expect(store.state.editMode).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('enters edit mode if file is binary', (done) => {
      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
        binary: true,
      }).then(() => {
        expect(store.state.editMode).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('creates flash message is file already exists', (done) => {
      store.state.tree.push(file('test', '1', 'blob'));

      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then(() => {
        expect(document.querySelector('.flash-alert')).not.toBeNull();

        done();
      }).catch(done.fail);
    });

    it('increases level of file', (done) => {
      store.state.level = 1;

      store.dispatch('createTempFile', {
        tree: store.state,
        name: 'test',
      }).then((f) => {
        expect(f.level).toBe(2);

        done();
      }).catch(done.fail);
    });
  });

  describe('getFileHTML', () => {
    let localFile;

    beforeEach(() => {
      localFile = file();
      Object.assign(localFile, {
        active: true,
        opened: true,
        rich: Object.assign(localFile.rich, { path: 'richPath' }),
      });

      store.state.openFiles.push(localFile);
    });

    describe('success', () => {
      beforeEach(() => {
        spyOn(service, 'getFileHTML').and.returnValue(Promise.resolve({
          json: () => Promise.resolve({
            html: 'fileHTML',
          }),
        }));
      });

      it('calls service', (done) => {
        store.dispatch('getFileHTML', { file: localFile })
          .then(() => {
            expect(service.getFileHTML).toHaveBeenCalledWith('richPath', false);

            done();
          }).catch(done.fail);
      });

      it('does not call service if already has HTML', (done) => {
        localFile.rich.html = 'testing';

        store.dispatch('getFileHTML', { file: localFile })
          .then(() => {
            expect(service.getFileHTML).not.toHaveBeenCalled();

            done();
          }).catch(done.fail);
      });

      it('sets viewer as loading', (done) => {
        store.dispatch('getFileHTML', { file: localFile })
          .then(() => {
            expect(localFile.rich.loading).toBeTruthy();

            return Vue.nextTick();
          })
          .then(() => {
            expect(localFile.rich.loading).toBeFalsy();

            done();
          }).catch(done.fail);
      });

      it('updates file data', (done) => {
        store.dispatch('getFileHTML', { file: localFile })
          .then(Vue.nextTick)
          .then(() => {
            expect(localFile.rich.html).toBe('fileHTML');

            done();
          }).catch(done.fail);
      });

      it('does not call service if file has renderError', (done) => {
        localFile.rich.renderError = 'error';

        store.dispatch('getFileHTML', { file: localFile })
          .then(() => {
            expect(service.getFileHTML).not.toHaveBeenCalled();

            done();
          }).catch(done.fail);
      });

      it('calls service if file has renderError and expanded is true', (done) => {
        localFile.rich.renderError = 'error';

        store.dispatch('getFileHTML', { file: localFile, expanded: true })
          .then(() => {
            expect(service.getFileHTML).toHaveBeenCalled();

            done();
          }).catch(done.fail);
      });

      it('resets renderError if expanded is true', (done) => {
        localFile.rich.renderError = 'error';

        store.dispatch('getFileHTML', { file: localFile, expanded: true })
          .then(Vue.nextTick)
          .then(() => {
            expect(localFile.rich.renderError).not.toBe('error');

            done();
          }).catch(done.fail);
      });
    });

    describe('failed', () => {
      beforeEach(() => {
        spyOn(service, 'getFileHTML').and.returnValue(Promise.reject());

        document.body.innerHTML += '<div class="flash-container"></div>';
      });

      afterEach(() => {
        document.querySelector('.flash-container').remove();
      });

      it('shows flash message', (done) => {
        store.dispatch('getFileHTML', localFile)
          .then(Vue.nextTick)
          .then(() => {
            expect(document.querySelector('.flash-alert')).not.toBeNull();
            expect(
              document.querySelector('.flash-alert').textContent.trim(),
            ).toBe('Error fetching file viewer. Please try again.');

            done();
          }).catch(done.fail);
      });
    });
  });

  describe('changeFileViewer', () => {
    let localFile;
    let oldGetFileHTML;
    let getFileHTMLSpy;

    beforeEach(() => {
      oldGetFileHTML = store._actions.getFileHTML; // eslint-disable-line
      getFileHTMLSpy = jasmine.createSpy('getFileHTML');
      store._actions.getFileHTML = [getFileHTMLSpy]; // eslint-disable-line

      localFile = file();
    });

    afterEach(() => {
      store._actions.getFileHTML = oldGetFileHTML; // eslint-disable-line
    });

    it('calls getFileHTML', (done) => {
      store.dispatch('changeFileViewer', {
        file: localFile,
        type: 'simple',
      }).then(() => {
        expect(getFileHTMLSpy).toHaveBeenCalledWith({ file: localFile });

        done();
      }).catch(done.fail);
    });

    it('does not call getFileHTML if current view matches passed in type', (done) => {
      store.dispatch('changeFileViewer', {
        file: localFile,
        type: 'rich',
      }).then(() => {
        expect(getFileHTMLSpy).not.toHaveBeenCalled();

        done();
      }).catch(done.fail);
    });

    it('sets current viewer type', (done) => {
      store.dispatch('changeFileViewer', {
        file: localFile,
        type: 'simple',
      }).then(() => {
        expect(localFile.currentViewer).toBe('simple');

        done();
      }).catch(done.fail);
    });
  });
});
