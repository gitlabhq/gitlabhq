import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { projectData, branches } from 'spec/ide/mock_data';
import { resetStore } from 'spec/ide/helpers';
import NewMergeRequestOption from '~/ide/components/commit_sidebar/new_merge_request_option.vue';
import store from '~/ide/stores';
import consts from '../../../../../app/assets/javascripts/ide/stores/modules/commit/constants';

describe('create new MR checkbox', () => {
  let vm;
  const setMR = () => {
    vm.$store.state.currentMergeRequestId = '1';
    vm.$store.state.projects[store.state.currentProjectId].mergeRequests[
      store.state.currentMergeRequestId
    ] = { foo: 'bar' };
  };

  const createComponent = ({ currentBranchId = 'master', createNewBranch = false } = {}) => {
    const Component = Vue.extend(NewMergeRequestOption);

    vm = createComponentWithStore(Component, store);

    vm.$store.state.commit.commitAction = createNewBranch
      ? consts.COMMIT_TO_NEW_BRANCH
      : consts.COMMIT_TO_CURRENT_BRANCH;

    vm.$store.state.currentBranchId = currentBranchId;
    vm.$store.state.currentProjectId = 'abcproject';

    const proj = JSON.parse(JSON.stringify(projectData));
    proj.branches[currentBranchId] = branches.find(branch => branch.name === currentBranchId);

    Vue.set(vm.$store.state.projects, 'abcproject', proj);

    return vm.$mount();
  };

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  describe('for default branch', () => {
    describe('is rendered when pushing to a new branch', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'master',
          createNewBranch: true,
        });
      });

      it('has NO new MR', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('has new MR', done => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).not.toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('is NOT rendered when pushing to the same branch', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'master',
          createNewBranch: false,
        });
      });

      it('has NO new MR', () => {
        expect(vm.$el.textContent).toBe('');
      });

      it('has new MR', done => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('for protected branch', () => {
    describe('when user does not have the write access', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'protected/no-access',
        });
      });

      it('is rendered if MR does not exists', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('is rendered if MR exists', done => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).not.toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('when user has the write access', () => {
      beforeEach(() => {
        createComponent({
          currentBranchId: 'protected/access',
        });
      });

      it('is rendered if MR does not exist', () => {
        expect(vm.$el.textContent).not.toBe('');
      });

      it('is hidden if MR exists', done => {
        setMR();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.textContent).toBe('');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('for regular branch', () => {
    beforeEach(() => {
      createComponent({
        currentBranchId: 'regular',
      });
    });

    it('is rendered if no MR exists', () => {
      expect(vm.$el.textContent).not.toBe('');
    });

    it('is hidden if MR exists', done => {
      setMR();

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.textContent).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });
  });

  it('dispatches toggleShouldCreateMR when clicking checkbox', () => {
    createComponent({
      currentBranchId: 'regular',
    });
    const el = vm.$el.querySelector('input[type="checkbox"]');
    spyOn(vm.$store, 'dispatch');
    el.dispatchEvent(new Event('change'));

    expect(vm.$store.dispatch.calls.allArgs()).toEqual(
      jasmine.arrayContaining([['commit/toggleShouldCreateMR', jasmine.any(Object)]]),
    );
  });
});
