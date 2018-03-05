import Vue from 'vue';
import store from 'ee/ide/stores';
import service from 'ee/ide/services';
import router from 'ee/ide/ide_router';
import { file, resetStore } from '../../helpers';

describe('Multi-file store tree actions', () => {
  let projectTree;

  const basicCallParameters = {
    endpoint: 'rootEndpoint',
    projectId: 'abcproject',
    branch: 'master',
  };

  beforeEach(() => {
    spyOn(router, 'push');

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = {
      web_url: '',
      branches: {
        master: {
          workingReference: '1',
        },
      },
    };
  });

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
          trees: [{ name: 'tree', path: 'tree' }],
          blobs: [{ name: 'blob' }],
          submodules: [{ name: 'submodule' }],
        }),
      }));
    });

    it('calls service getTreeData', (done) => {
      store.dispatch('getTreeData', basicCallParameters)
      .then(() => {
        expect(service.getTreeData).toHaveBeenCalledWith('rootEndpoint');

        done();
      }).catch(done.fail);
    });

    it('adds data into tree', (done) => {
      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          projectTree = store.state.trees['abcproject/master'];
          expect(projectTree.tree.length).toBe(3);
          expect(projectTree.tree[0].type).toBe('tree');
          expect(projectTree.tree[1].type).toBe('submodule');
          expect(projectTree.tree[2].type).toBe('blob');

          done();
        }).catch(done.fail);
    });

    it('adds temp files into tree', (done) => {
      const f = {
        ...file('tempFile'),
        path: 'tree/tempFile',
        tempFile: true,
      };

      store.state.changedFiles.push(f);

      store.dispatch('getTreeData', basicCallParameters)
        .then(() => store.dispatch('getTreeData', {
          ...basicCallParameters,
          tree: store.state.trees['abcproject/master'].tree[0],
        }))
        .then(() => {
          const tree = store.state.trees['abcproject/master'].tree[0].tree;

          expect(tree.length).toBe(4);
          expect(tree[3].name).toBe(f.name);

          done();
        }).catch(done.fail);
    });

    it('sets parent tree URL', (done) => {
      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          expect(store.state.parentTreeUrl).toBe('parent_tree_url');

          done();
        }).catch(done.fail);
    });

    it('sets last commit path', (done) => {
      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          expect(store.state.trees['abcproject/master'].lastCommitPath).toBe('last_commit_path');

          done();
        }).catch(done.fail);
    });

    it('sets root if not currently at root', (done) => {
      store.state.isInitialRoot = false;

      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          expect(store.state.isInitialRoot).toBeTruthy();
          expect(store.state.isRoot).toBeTruthy();

          done();
        }).catch(done.fail);
    });

    it('sets page title', (done) => {
      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          expect(document.title).toBe('test');

          done();
        }).catch(done.fail);
    });

    it('calls getLastCommitData if prevLastCommitPath is not null', (done) => {
      const getLastCommitDataSpy = jasmine.createSpy('getLastCommitData');
      const oldGetLastCommitData = store._actions.getLastCommitData; // eslint-disable-line
      store._actions.getLastCommitData = [getLastCommitDataSpy]; // eslint-disable-line
      store.state.prevLastCommitPath = 'test';

      store.dispatch('getTreeData', basicCallParameters)
        .then(() => {
          expect(getLastCommitDataSpy).toHaveBeenCalledWith(projectTree);

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
        projectId: 'abcproject',
        branchId: 'master',
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
          projectId: 'abcproject',
          branch: 'master',
          endpoint: 'test',
          tree,
        });

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
  });

  describe('createTempTree', () => {
    beforeEach(() => {
      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };
      projectTree = store.state.trees['abcproject/mybranch'];
    });

    it('creates temp tree', (done) => {
      store.dispatch('createTempTree', {
        projectId: store.state.currentProjectId,
        branchId: store.state.currentBranchId,
        name: 'test',
        parent: projectTree,
      })
      .then(() => {
        expect(projectTree.tree[0].name).toBe('test');
        expect(projectTree.tree[0].type).toBe('tree');

        done();
      }).catch(done.fail);
    });

    it('creates new folder inside another tree', (done) => {
      const tree = {
        type: 'tree',
        name: 'testing',
        tree: [],
      };

      projectTree.tree.push(tree);

      store.dispatch('createTempTree', {
        projectId: store.state.currentProjectId,
        branchId: store.state.currentBranchId,
        name: 'testing/test',
        parent: projectTree,
      })
      .then(() => {
        expect(projectTree.tree[0].name).toBe('testing');
        expect(projectTree.tree[0].tree[0].tempFile).toBeTruthy();
        expect(projectTree.tree[0].tree[0].name).toBe('test');
        expect(projectTree.tree[0].tree[0].type).toBe('tree');

        done();
      }).catch(done.fail);
    });

    it('does not create new tree if already exists', (done) => {
      const tree = {
        type: 'tree',
        name: 'testing',
        endpoint: 'test',
        tree: [],
      };

      projectTree.tree.push(tree);

      store.dispatch('createTempTree', {
        projectId: store.state.currentProjectId,
        branchId: store.state.currentBranchId,
        name: 'testing/test',
        parent: projectTree,
      })
      .then(() => {
        expect(projectTree.tree[0].name).toBe('testing');
        expect(projectTree.tree[0].tempFile).toBeUndefined();

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

      store.state.trees['abcproject/mybranch'] = {
        tree: [],
      };

      projectTree = store.state.trees['abcproject/mybranch'];
      projectTree.tree.push(file('testing', '1', 'tree'));
      projectTree.lastCommitPath = 'lastcommitpath';
    });

    it('calls service with lastCommitPath', (done) => {
      store.dispatch('getLastCommitData', projectTree)
        .then(() => {
          expect(service.getTreeLastCommit).toHaveBeenCalledWith('lastcommitpath');

          done();
        }).catch(done.fail);
    });

    it('updates trees last commit data', (done) => {
      store.dispatch('getLastCommitData', projectTree)
      .then(Vue.nextTick)
        .then(() => {
          expect(projectTree.tree[0].lastCommit.message).toBe('commit message');

          done();
        }).catch(done.fail);
    });

    it('does not update entry if not found', (done) => {
      projectTree.tree[0].name = 'a';

      store.dispatch('getLastCommitData', projectTree)
        .then(Vue.nextTick)
        .then(() => {
          expect(projectTree.tree[0].lastCommit.message).not.toBe('commit message');

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

    it('adds changed state of an already existing file', (done) => {
      const f = file('changedFile');
      const tree = {
        tree: [],
      };
      const data = {
        trees: [{ name: 'tree' }],
        submodules: [{ name: 'submodule' }],
        blobs: [f],
      };

      store.state.changedFiles.push({
        ...f,
        type: 'blob',
        changed: true,
      });

      store.dispatch('updateDirectoryData', {
        data,
        tree,
        clearTree: false,
      }).then(() => {
        expect(tree.tree[2].changed).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('adds opened state of an already existing file', (done) => {
      const f = file('openedFile');
      const tree = {
        tree: [],
      };
      const data = {
        trees: [{ name: 'tree' }],
        submodules: [{ name: 'submodule' }],
        blobs: [f],
      };

      store.state.openFiles.push({
        ...f,
        type: 'blob',
        opened: true,
      });

      store.dispatch('updateDirectoryData', {
        data,
        tree,
        clearTree: false,
      }).then(() => {
        expect(tree.tree[2].opened).toBeTruthy();

        done();
      }).catch(done.fail);
    });

    it('does not add changed file with same name but different path', (done) => {
      const f = file('openedFile');
      const tree = {
        tree: [],
      };
      const data = {
        trees: [{ name: 'tree' }],
        submodules: [{ name: 'submodule' }],
        blobs: [f],
      };

      store.state.changedFiles.push({
        ...f,
        type: 'blob',
        path: `src/${f.name}`,
        changed: true,
      });

      store.dispatch('updateDirectoryData', {
        data,
        tree,
        clearTree: false,
      }).then(() => {
        expect(tree.tree[2].changed).toBeFalsy();

        done();
      }).catch(done.fail);
    });

    it('does not add opened file with same name but different path', (done) => {
      const f = file('openedFile');
      const tree = {
        tree: [],
      };
      const data = {
        trees: [{ name: 'tree' }],
        submodules: [{ name: 'submodule' }],
        blobs: [f],
      };

      store.state.openFiles.push({
        ...f,
        type: 'blob',
        path: `src/${f.name}`,
        opened: true,
      });

      store.dispatch('updateDirectoryData', {
        data,
        tree,
        clearTree: false,
      }).then(() => {
        expect(tree.tree[2].opened).toBeFalsy();

        done();
      }).catch(done.fail);
    });
  });
});
