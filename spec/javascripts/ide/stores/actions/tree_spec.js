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
    branchId: 'master',
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

  describe('getFiles', () => {
    beforeEach(() => {
      spyOn(service, 'getFiles').and.returnValue(Promise.resolve({
        json: () => Promise.resolve([
          'file.txt',
          'folder/fileinfolder.js',
          'folder/subfolder/fileinsubfolder.js',
        ]),
      }));
    });

    it('calls service getFiles', (done) => {
      store.dispatch('getFiles', basicCallParameters)
      .then(() => {
        expect(service.getFiles).toHaveBeenCalledWith('', 'master');

        done();
      }).catch(done.fail);
    });

    it('adds data into tree', (done) => {
      store.dispatch('getFiles', basicCallParameters)
        .then(() => {
          projectTree = store.state.trees['abcproject/master'];
          expect(projectTree.tree.length).toBe(2);
          expect(projectTree.tree[0].type).toBe('tree');
          expect(projectTree.tree[0].tree[1].name).toBe('fileinfolder.js');
          expect(projectTree.tree[1].type).toBe('blob');
          expect(projectTree.tree[0].tree[0].tree[0].type).toBe('blob');
          expect(projectTree.tree[0].tree[0].tree[0].name).toBe('fileinsubfolder.js');

          done();
        }).catch(done.fail);
    });
  });

  describe('toggleTreeOpen', () => {
    let tree;

    beforeEach(() => {
      tree = file('testing', '1', 'tree');
      store.state.entries[tree.path] = tree;
    });

    it('toggles the tree open', (done) => {
      store.dispatch('toggleTreeOpen', tree.path).then(() => {
        expect(tree.opened).toBeTruthy();

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
});
