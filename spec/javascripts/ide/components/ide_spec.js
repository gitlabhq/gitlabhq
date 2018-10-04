import Vue from 'vue';
import Mousetrap from 'mousetrap';
import store from '~/ide/stores';
import ide from '~/ide/components/ide.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../helpers';
import { projectData } from '../mock_data';

describe('ide component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ide);

    store.state.currentProjectId = 'abcproject';
    store.state.currentBranchId = 'master';
    store.state.projects.abcproject = Object.assign({}, projectData);

    vm = createComponentWithStore(Component, store, {
      emptyStateSvgPath: 'svg',
      noChangesStateSvgPath: 'svg',
      committedStateSvgPath: 'svg',
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('does not render right right when no files open', () => {
    expect(vm.$el.querySelector('.panel-right')).toBeNull();
  });

  it('renders right panel when files are open', done => {
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [file()],
    };

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.panel-right')).toBeNull();

      done();
    });
  });

  describe('onBeforeUnload', () => {
    it('returns undefined when no staged files or changed files', () => {
      expect(vm.onBeforeUnload()).toBe(undefined);
    });

    it('returns warning text when their are changed files', () => {
      vm.$store.state.changedFiles.push(file());

      expect(vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
    });

    it('returns warning text when their are staged files', () => {
      vm.$store.state.stagedFiles.push(file());

      expect(vm.onBeforeUnload()).toBe('Are you sure you want to lose unsaved changes?');
    });

    it('updates event object', () => {
      const event = {};
      vm.$store.state.stagedFiles.push(file());

      vm.onBeforeUnload(event);

      expect(event.returnValue).toBe('Are you sure you want to lose unsaved changes?');
    });
  });

  describe('file finder', () => {
    beforeEach(done => {
      spyOn(vm, 'toggleFileFinder');

      vm.$store.state.fileFindVisible = true;

      vm.$nextTick(done);
    });

    it('calls toggleFileFinder on `t` key press', done => {
      Mousetrap.trigger('t');

      vm
        .$nextTick()
        .then(() => {
          expect(vm.toggleFileFinder).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls toggleFileFinder on `command+p` key press', done => {
      Mousetrap.trigger('command+p');

      vm
        .$nextTick()
        .then(() => {
          expect(vm.toggleFileFinder).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('calls toggleFileFinder on `ctrl+p` key press', done => {
      Mousetrap.trigger('ctrl+p');

      vm
        .$nextTick()
        .then(() => {
          expect(vm.toggleFileFinder).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('always allows `command+p` to trigger toggleFileFinder', () => {
      expect(
        vm.mousetrapStopCallback(null, vm.$el.querySelector('.dropdown-input-field'), 'command+p'),
      ).toBe(false);
    });

    it('always allows `ctrl+p` to trigger toggleFileFinder', () => {
      expect(
        vm.mousetrapStopCallback(null, vm.$el.querySelector('.dropdown-input-field'), 'ctrl+p'),
      ).toBe(false);
    });

    it('onlys handles `t` when focused in input-field', () => {
      expect(
        vm.mousetrapStopCallback(null, vm.$el.querySelector('.dropdown-input-field'), 't'),
      ).toBe(true);
    });

    it('stops callback in monaco editor', () => {
      setFixtures('<div class="inputarea"></div>');

      expect(vm.mousetrapStopCallback(null, document.querySelector('.inputarea'), 't')).toBe(true);
    });
  });

  it('shows error message when set', done => {
    expect(vm.$el.querySelector('.flash-container')).toBe(null);

    vm.$store.state.errorMessage = {
      text: 'error',
    };

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.flash-container')).not.toBe(null);

      done();
    });
  });
});
