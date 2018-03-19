import Vue from 'vue';
import store from 'ee/ide/stores';
import service from 'ee/ide/services';
import router from 'ee/ide/ide_router';
import eventHub from 'ee/ide/eventhub';
import { file, resetStore } from '../../helpers';

describe('Multi-file store file actions', () => {
  beforeEach(() => {
    spyOn(router, 'push');
  });

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

      localFile = file('testFile');
      localFile.active = true;
      localFile.opened = true;
      localFile.parentTreeUrl = 'parentTreeUrl';

      store.state.openFiles.push(localFile);
    });

    afterEach(() => {
      store._actions.getLastCommitData = oldGetLastCommitData; // eslint-disable-line
    });

    it('closes open files', (done) => {
      store.dispatch('closeFile', localFile)
        .then(() => {
          expect(localFile.opened).toBeFalsy();
          expect(localFile.active).toBeFalsy();
          expect(store.state.openFiles.length).toBe(0);

          done();
        }).catch(done.fail);
    });

    it('closes file even if file has changes', (done) => {
      store.state.changedFiles.push(localFile);

      store.dispatch('closeFile', localFile)
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.openFiles.length).toBe(0);
          expect(store.state.changedFiles.length).toBe(1);

          done();
        })
        .catch(done.fail);
    });

    it('calls getLastCommitData', (done) => {
      store.dispatch('closeFile', localFile)
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
      store.dispatch('setFileActive', file('setThisActive'))
        .then(() => {
          expect(scrollToTabSpy).toHaveBeenCalled();

          done();
        }).catch(done.fail);
    });

    it('sets the file active', (done) => {
      const localFile = file('activeFile');

      store.dispatch('setFileActive', localFile)
        .then(() => {
          expect(localFile.active).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('returns early if file is already active', (done) => {
      const localFile = file('earlyActive');
      localFile.active = true;

      store.dispatch('setFileActive', localFile)
        .then(() => {
          expect(scrollToTabSpy).not.toHaveBeenCalled();

          done();
        }).catch(done.fail);
    });

    it('sets current active file to not active', (done) => {
      const localFile = file('currentActive');
      localFile.active = true;
      store.state.openFiles.push(localFile);

      store.dispatch('setFileActive', file('newActive'))
        .then(() => {
          expect(localFile.active).toBeFalsy();

          done();
        }).catch(done.fail);
    });

    it('resets location.hash for line highlighting', (done) => {
      location.hash = 'test';

      store.dispatch('setFileActive', file('otherActive'))
        .then(() => {
          expect(location.hash).not.toBe('test');

          done();
        }).catch(done.fail);
    });
  });

  describe('getFileData', () => {
    let localFile;

    beforeEach(() => {
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
          html: '123',
          render_error: '',
        }),
      }));

      localFile = file(`newCreate-${Math.random()}`);
      localFile.url = 'getFileDataURL';
    });

    afterEach(() => {
      store.dispatch('closeFile', {
        file: localFile,
        force: true,
      });
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
  });

  describe('getRawFileData', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(service, 'getRawFileData').and.returnValue(Promise.resolve('raw'));

      tmpFile = file('tmpFile');
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
      tmpFile = file('tmpFile');
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

    it('adds file into changedFiles array', (done) => {
      store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content',
      })
      .then(() => {
        expect(store.state.changedFiles.length).toBe(1);

        done();
      }).catch(done.fail);
    });

    it('adds file once into changedFiles array', (done) => {
      store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content',
      })
      .then(() => store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content 123',
      }))
      .then(() => {
        expect(store.state.changedFiles.length).toBe(1);

        done();
      }).catch(done.fail);
    });

    it('removes file from changedFiles array if not changed', (done) => {
      store.dispatch('changeFileContent', {
        file: tmpFile,
        content: 'content',
      })
      .then(() => store.dispatch('changeFileContent', {
        file: tmpFile,
        content: '',
      }))
      .then(() => {
        expect(store.state.changedFiles.length).toBe(0);

        done();
      }).catch(done.fail);
    });
  });

  describe('createTempFile', () => {
    let projectTree;

    beforeEach(() => {
      document.body.innerHTML += '<div class="flash-container"></div>';

      store.state.currentProjectId = 'abcproject';
      store.state.currentBranchId = 'master';
      store.state.projects.abcproject = {
        branches: {
          master: {
            workingReference: '1',
          },
        },
      };

      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };

      projectTree = store.state.trees['abcproject/mybranch'];
    });

    afterEach(() => {
      document.querySelector('.flash-container').remove();
    });

    it('creates temp file', (done) => {
      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then((f) => {
        expect(f.tempFile).toBeTruthy();
        expect(store.state.trees['abcproject/mybranch'].tree.length).toBe(1);

        done();
      }).catch(done.fail);
    });

    it('adds tmp file to open files', (done) => {
      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then((f) => {
        expect(store.state.openFiles.length).toBe(1);
        expect(store.state.openFiles[0].name).toBe(f.name);

        done();
      }).catch(done.fail);
    });

    it('adds tmp file to changed files', (done) => {
      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then((f) => {
        expect(store.state.changedFiles.length).toBe(1);
        expect(store.state.changedFiles[0].name).toBe(f.name);

        done();
      }).catch(done.fail);
    });

    it('sets tmp file as active', (done) => {
      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then((f) => {
        expect(f.active).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('enters edit mode if file is not base64', (done) => {
      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then(() => {
        expect(store.state.editMode).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('creates flash message is file already exists', (done) => {
      store.state.trees['abcproject/mybranch'].tree.push(file('test', '1', 'blob'));

      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then(() => {
        expect(document.querySelector('.flash-alert')).not.toBeNull();

        done();
      }).catch(done.fail);
    });

    it('increases level of file', (done) => {
      store.state.trees['abcproject/mybranch'].level = 1;

      store.dispatch('createTempFile', {
        name: 'test',
        projectId: 'abcproject',
        branchId: 'mybranch',
        parent: projectTree,
      }).then((f) => {
        expect(f.level).toBe(2);

        done();
      }).catch(done.fail);
    });
  });

  describe('discardFileChanges', () => {
    let tmpFile;

    beforeEach(() => {
      spyOn(eventHub, '$on');

      tmpFile = file();
      tmpFile.content = 'testing';

      store.state.changedFiles.push(tmpFile);
    });

    it('resets file content', (done) => {
      store.dispatch('discardFileChanges', tmpFile)
      .then(() => {
        expect(tmpFile.content).not.toBe('testing');

        done();
      })
      .catch(done.fail);
    });

    it('removes file from changedFiles array', (done) => {
      store.dispatch('discardFileChanges', tmpFile)
      .then(() => {
        expect(store.state.changedFiles.length).toBe(0);

        done();
      })
      .catch(done.fail);
    });

    it('closes temp file', (done) => {
      tmpFile.tempFile = true;
      tmpFile.opened = true;

      store.dispatch('discardFileChanges', tmpFile)
      .then(() => {
        expect(tmpFile.opened).toBeFalsy();

        done();
      })
      .catch(done.fail);
    });

    it('does not re-open a closed temp file', (done) => {
      tmpFile.tempFile = true;

      expect(tmpFile.opened).toBeFalsy();

      store.dispatch('discardFileChanges', tmpFile)
      .then(() => {
        expect(tmpFile.opened).toBeFalsy();

        done();
      })
      .catch(done.fail);
    });
  });
});
