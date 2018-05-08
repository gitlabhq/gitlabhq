import Vue from 'vue';
import store from '~/ide/stores';
import CommitForm from '~/ide/components/commit_sidebar/form.vue';
import { activityBarViews } from '~/ide/constants';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import getSetTimeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import { resetStore } from '../../helpers';

describe('IDE commit form', () => {
  const Component = Vue.extend(CommitForm);
  let vm;

  beforeEach(() => {
    spyOnProperty(window, 'innerHeight').and.returnValue(800);

    store.state.changedFiles.push('test');

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('enables button when has changes', () => {
    expect(vm.$el.querySelector('[disabled]')).toBe(null);
  });

  describe('compact', () => {
    it('renders commit button in compact mode', () => {
      expect(vm.$el.querySelector('.btn-primary')).not.toBeNull();
      expect(vm.$el.querySelector('.btn-primary').textContent).toContain('Commit');
    });

    it('does not render form', () => {
      expect(vm.$el.querySelector('form')).toBeNull();
    });

    it('renders overview text', done => {
      vm.$store.state.stagedFiles.push('test');

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('p').textContent).toContain('1 unstaged and 1 staged changes');
        done();
      });
    });

    it('shows form when clicking commit button', done => {
      vm.$el.querySelector('.btn-primary').click();

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('form')).not.toBeNull();

        done();
      });
    });

    it('toggles activity bar vie when clicking commit button', done => {
      vm.$el.querySelector('.btn-primary').click();

      vm.$nextTick(() => {
        expect(store.state.currentActivityView).toBe(activityBarViews.commit);

        done();
      });
    });
  });

  describe('full', () => {
    beforeEach(done => {
      vm.isCompact = false;

      vm.$nextTick(done);
    });

    it('updates commitMessage in store on input', done => {
      const textarea = vm.$el.querySelector('textarea');

      textarea.value = 'testing commit message';

      textarea.dispatchEvent(new Event('input'));

      getSetTimeoutPromise()
        .then(() => {
          expect(vm.$store.state.commit.commitMessage).toBe('testing commit message');
        })
        .then(done)
        .catch(done.fail);
    });

    it('updating currentActivityView not to commit view sets compact mode', done => {
      store.state.currentActivityView = 'a';

      vm.$nextTick(() => {
        expect(vm.isCompact).toBe(true);

        done();
      });
    });

    describe('discard draft button', () => {
      it('hidden when commitMessage is empty', () => {
        expect(vm.$el.querySelector('.btn-default').textContent).toContain('Collapse');
      });

      it('resets commitMessage when clicking discard button', done => {
        vm.$store.state.commit.commitMessage = 'testing commit message';

        getSetTimeoutPromise()
          .then(() => {
            vm.$el.querySelector('.btn-default').click();
          })
          .then(Vue.nextTick)
          .then(() => {
            expect(vm.$store.state.commit.commitMessage).not.toBe('testing commit message');
          })
          .then(done)
          .catch(done.fail);
      });
    });

    describe('when submitting', () => {
      beforeEach(() => {
        spyOn(vm, 'commitChanges');
        vm.$store.state.stagedFiles.push('test');
      });

      it('calls commitChanges', done => {
        vm.$store.state.commit.commitMessage = 'testing commit message';

        getSetTimeoutPromise()
          .then(() => {
            vm.$el.querySelector('.btn-success').click();
          })
          .then(Vue.nextTick)
          .then(() => {
            expect(vm.commitChanges).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
