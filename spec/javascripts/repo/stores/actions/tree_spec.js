import Vue from 'vue';
import store from '~/repo/stores';
import service from '~/repo/services';
import { file, resetStore } from '../../helpers';

describe('Multi-file store tree actions', () => {
  afterEach(() => {
    resetStore(store);
  });

  describe('getTreeData', () => {
    beforeEach(() => {
      spyOn(service, 'getTreeData').and.returnValue(Promise.resolve({
        headers: {
          'page-title': 'test',
        },
        json: () => Promise.resolve({
          last_commit_path: 'last_commit_path',
          parent_tree_url: 'parent_tree_url',
          path: '/',
          trees: [{ name: 'tree' }],
          blobs: [{ name: 'blob' }],
          submodules: [{ name: 'submodule' }],
        }),
      }));
      spyOn(history, 'pushState');

      Object.assign(store.state.endpoints, {
        rootEndpoint: 'rootEndpoint',
      });
    });

    it('calls service getTreeData', (done) => {
      store.dispatch('getTreeData')
        .then(() => {
          expect(service.getTreeData).toHaveBeenCalledWith('rootEndpoint');

          done();
        }).catch(done.fail);
    });

    it('adds data into tree', (done) => {
      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.tree.length).toBe(3);
          expect(store.state.tree[0].type).toBe('tree');
          expect(store.state.tree[1].type).toBe('submodule');
          expect(store.state.tree[2].type).toBe('blob');

          done();
        }).catch(done.fail);
    });

    it('sets parent tree URL', (done) => {
      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.parentTreeUrl).toBe('parent_tree_url');

          done();
        }).catch(done.fail);
    });

    it('sets last commit path', (done) => {
      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.lastCommitPath).toBe('last_commit_path');

          done();
        }).catch(done.fail);
    });

    it('sets root if not currently at root', (done) => {
      store.state.isInitialRoot = false;

      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.isInitialRoot).toBeTruthy();
          expect(store.state.isRoot).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('sets page title', (done) => {
      store.dispatch('getTreeData')
        .then(() => {
          expect(document.title).toBe('test');

          done();
        }).catch(done.fail);
    });

    it('toggles loading', (done) => {
      store.dispatch('getTreeData')
        .then(() => {
          expect(store.state.loading).toBeTruthy();

          return Vue.nextTick();
        })
        .then(() => {
          expect(store.state.loading).toBeFalsy();

          done();
        }).catch(done.fail);
    });

    it('calls pushState with endpoint', (done) => {
      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(history.pushState).toHaveBeenCalledWith(jasmine.anything(), '', 'rootEndpoint');

          done();
        }).catch(done.fail);
    });

    it('calls getLastCommitData if prevLastCommitPath is not null', (done) => {
      const getLastCommitDataSpy = jasmine.createSpy('getLastCommitData');
      const oldGetLastCommitData = store._actions.getLastCommitData; // eslint-disable-line
      store._actions.getLastCommitData = [getLastCommitDataSpy]; // eslint-disable-line
      store.state.prevLastCommitPath = 'test';

      store.dispatch('getTreeData')
        .then(Vue.nextTick)
        .then(() => {
          expect(getLastCommitDataSpy).toHaveBeenCalledWith(store.state);

          store._actions.getLastCommitData = oldGetLastCommitData; // eslint-disable-line

          done();
        }).catch(done.fail);
    });
  });

  describe('toggleTreeOpen', () => {
    let oldGetTreeData;
    let getTreeDataSpy;
    let tree;

    beforeEach(() => {
      getTreeDataSpy = jasmine.createSpy('getTreeData');

      oldGetTreeData = store._actions.getTreeData;  // eslint-disable-line
      store._actions.getTreeData = [getTreeDataSpy]; // eslint-disable-line

      tree = {
        opened: false,
        tree: [],
      };
    });

    afterEach(() => {
      store._actions.getTreeData = oldGetTreeData; // eslint-disable-line
    });

    it('toggles the tree open', (done) => {
      store.dispatch('toggleTreeOpen', {
        endpoint: 'test',
        tree,
      }).then(() => {
        expect(tree.opened).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('calls getTreeData if tree is closed', (done) => {
      store.dispatch('toggleTreeOpen', {
        endpoint: 'test',
        tree,
      }).then(() => {
        expect(getTreeDataSpy).toHaveBeenCalledWith({
          endpoint: 'test',
          tree,
        });
        expect(store.state.previousUrl).toBe('test');

        done();
      }).catch(done.fail);
    });

    it('resets entries tree', (done) => {
      Object.assign(tree, {
        opened: true,
        tree: ['a'],
      });

      store.dispatch('toggleTreeOpen', {
        endpoint: 'test',
        tree,
      }).then(() => {
        expect(tree.tree.length).toBe(0);

        done();
      }).catch(done.fail);
    });

    it('pushes new state', (done) => {
      spyOn(history, 'pushState');
      Object.assign(tree, {
        opened: true,
        parentTreeUrl: 'testing',
      });

      store.dispatch('toggleTreeOpen', {
        endpoint: 'test',
        tree,
      }).then(() => {
        expect(history.pushState).toHaveBeenCalledWith(jasmine.anything(), '', 'testing');

        done();
      }).catch(done.fail);
    });
  });

  describe('clickedTreeRow', () => {
    describe('tree', () => {
      let toggleTreeOpenSpy;
      let oldToggleTreeOpen;

      beforeEach(() => {
        toggleTreeOpenSpy = jasmine.createSpy('toggleTreeOpen');

        oldToggleTreeOpen = store._actions.toggleTreeOpen; // eslint-disable-line
        store._actions.toggleTreeOpen = [toggleTreeOpenSpy]; // eslint-disable-line
      });

      afterEach(() => {
        store._actions.toggleTreeOpen = oldToggleTreeOpen; // eslint-disable-line
      });

      it('opens tree', (done) => {
        const tree = {
          url: 'a',
          type: 'tree',
        };

        store.dispatch('clickedTreeRow', tree)
          .then(() => {
            expect(toggleTreeOpenSpy).toHaveBeenCalledWith({
              endpoint: tree.url,
              tree,
            });

            done();
          }).catch(done.fail);
      });
    });

    describe('submodule', () => {
      let row;

      beforeEach(() => {
        spyOn(gl.utils, 'visitUrl');

        row = {
          url: 'submoduleurl',
          type: 'submodule',
          loading: false,
        };
      });

      it('toggles loading for row', (done) => {
        store.dispatch('clickedTreeRow', row)
          .then(() => {
            expect(row.loading).toBeTruthy();

            done();
          }).catch(done.fail);
      });

      it('opens submodule URL', (done) => {
        store.dispatch('clickedTreeRow', row)
          .then(() => {
            expect(gl.utils.visitUrl).toHaveBeenCalledWith('submoduleurl');

            done();
          }).catch(done.fail);
      });
    });

    describe('blob', () => {
      let row;

      beforeEach(() => {
        row = {
          type: 'blob',
          opened: false,
        };
      });

      it('calls getFileData', (done) => {
        const getFileDataSpy = jasmine.createSpy('getFileData');
        const oldGetFileData = store._actions.getFileData; // eslint-disable-line
        store._actions.getFileData = [getFileDataSpy]; // eslint-disable-line

        store.dispatch('clickedTreeRow', row)
          .then(() => {
            expect(getFileDataSpy).toHaveBeenCalledWith(row);

            store._actions.getFileData = oldGetFileData; // eslint-disable-line

            done();
          }).catch(done.fail);
      });

      it('calls setFileActive when file is opened', (done) => {
        const setFileActiveSpy = jasmine.createSpy('setFileActive');
        const oldSetFileActive = store._actions.setFileActive; // eslint-disable-line
        store._actions.setFileActive = [setFileActiveSpy]; // eslint-disable-line

        row.opened = true;

        store.dispatch('clickedTreeRow', row)
          .then(() => {
            expect(setFileActiveSpy).toHaveBeenCalledWith(row);

            store._actions.setFileActive = oldSetFileActive; // eslint-disable-line

            done();
          }).catch(done.fail);
      });
    });
  });

  describe('createTempTree', () => {
    it('creates temp tree', (done) => {
      store.dispatch('createTempTree', 'test')
        .then(() => {
          expect(store.state.tree[0].tempFile).toBeTruthy();
          expect(store.state.tree[0].name).toBe('test');
          expect(store.state.tree[0].type).toBe('tree');

          done();
        }).catch(done.fail);
    });

    it('creates .gitkeep file in temp tree', (done) => {
      store.dispatch('createTempTree', 'test')
        .then(() => {
          expect(store.state.tree[0].tree[0].tempFile).toBeTruthy();
          expect(store.state.tree[0].tree[0].name).toBe('.gitkeep');

          done();
        }).catch(done.fail);
    });

    it('creates new folder inside another tree', (done) => {
      const tree = {
        type: 'tree',
        name: 'testing',
        tree: [],
      };

      store.state.tree.push(tree);

      store.dispatch('createTempTree', 'testing/test')
        .then(() => {
          expect(store.state.tree[0].name).toBe('testing');
          expect(store.state.tree[0].tree[0].tempFile).toBeTruthy();
          expect(store.state.tree[0].tree[0].name).toBe('test');
          expect(store.state.tree[0].tree[0].type).toBe('tree');

          done();
        }).catch(done.fail);
    });

    it('does not create new tree if already exists', (done) => {
      const tree = {
        type: 'tree',
        name: 'testing',
        tree: [],
      };

      store.state.tree.push(tree);

      store.dispatch('createTempTree', 'testing/test')
        .then(() => {
          expect(store.state.tree[0].name).toBe('testing');
          expect(store.state.tree[0].tempFile).toBeUndefined();

          done();
        }).catch(done.fail);
    });
  });

  describe('getLastCommitData', () => {
    beforeEach(() => {
      spyOn(service, 'getTreeLastCommit').and.returnValue(Promise.resolve({
        headers: {
          'more-logs-url': null,
        },
        json: () => Promise.resolve([{
          type: 'tree',
          file_name: 'testing',
          commit: {
            message: 'commit message',
            authored_date: '123',
          },
        }]),
      }));

      store.state.tree.push(file('testing', '1', 'tree'));
      store.state.lastCommitPath = 'lastcommitpath';
    });

    it('calls service with lastCommitPath', (done) => {
      store.dispatch('getLastCommitData')
        .then(() => {
          expect(service.getTreeLastCommit).toHaveBeenCalledWith('lastcommitpath');

          done();
        }).catch(done.fail);
    });

    it('updates trees last commit data', (done) => {
      store.dispatch('getLastCommitData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.tree[0].lastCommit.message).toBe('commit message');

          done();
        }).catch(done.fail);
    });

    it('does not update entry if not found', (done) => {
      store.state.tree[0].name = 'a';

      store.dispatch('getLastCommitData')
        .then(Vue.nextTick)
        .then(() => {
          expect(store.state.tree[0].lastCommit.message).not.toBe('commit message');

          done();
        }).catch(done.fail);
    });
  });

  describe('updateDirectoryData', () => {
    it('adds data into tree', (done) => {
      const tree = {
        tree: [],
      };
      const data = {
        trees: [{ name: 'tree' }],
        submodules: [{ name: 'submodule' }],
        blobs: [{ name: 'blob' }],
      };

      store.dispatch('updateDirectoryData', {
        data,
        tree,
      }).then(() => {
        expect(tree.tree[0].name).toBe('tree');
        expect(tree.tree[0].type).toBe('tree');
        expect(tree.tree[1].name).toBe('submodule');
        expect(tree.tree[1].type).toBe('submodule');
        expect(tree.tree[2].name).toBe('blob');
        expect(tree.tree[2].type).toBe('blob');

        done();
      }).catch(done.fail);
    });
  });
});
