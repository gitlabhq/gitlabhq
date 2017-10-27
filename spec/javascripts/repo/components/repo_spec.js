import Vue from 'vue';
import repo from '~/repo/components/repo.vue';
import RepoStore from '~/repo/stores/repo_store';
import Service from '~/repo/services/repo_service';
import eventHub from '~/repo/event_hub';
import createComponent from '../../helpers/vue_mount_component_helper';

describe('repo component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(repo);

    RepoStore.currentBranch = 'master';

    vm = createComponent(Component);
  });

  afterEach(() => {
    vm.$destroy();

    RepoStore.currentBranch = '';
  });

  describe('createNewBranch', () => {
    beforeEach(() => {
      spyOn(history, 'pushState');
    });

    describe('success', () => {
      beforeEach(() => {
        spyOn(Service, 'createBranch').and.returnValue(Promise.resolve({
          data: {
            name: 'test',
          },
        }));
      });

      it('calls createBranch with branchName', () => {
        eventHub.$emit('createNewBranch', 'test');

        expect(Service.createBranch).toHaveBeenCalledWith({
          branch: 'test',
          ref: RepoStore.currentBranch,
        });
      });

      it('pushes new history state', (done) => {
        RepoStore.currentBranch = 'master';

        spyOn(vm, 'getCurrentLocation').and.returnValue('http://test.com/master');

        eventHub.$emit('createNewBranch', 'test');

        setTimeout(() => {
          expect(history.pushState).toHaveBeenCalledWith(jasmine.anything(), '', 'http://test.com/test');
          done();
        });
      });

      it('updates stores currentBranch', (done) => {
        eventHub.$emit('createNewBranch', 'test');

        setTimeout(() => {
          expect(RepoStore.currentBranch).toBe('test');

          done();
        });
      });
    });

    describe('failure', () => {
      beforeEach(() => {
        spyOn(Service, 'createBranch').and.returnValue(Promise.reject({
          response: {
            data: {
              message: 'test',
            },
          },
        }));
      });

      it('emits createNewBranchError event', (done) => {
        spyOn(eventHub, '$emit').and.callThrough();

        eventHub.$emit('createNewBranch', 'test');

        setTimeout(() => {
          expect(eventHub.$emit).toHaveBeenCalledWith('createNewBranchError', 'test');

          done();
        });
      });
    });
  });
});
