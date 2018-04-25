import Vue from 'vue';
import Mousetrap from 'mousetrap';
import store from '~/ide/stores';
import ide from '~/ide/components/ide.vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../helpers';

describe('ide component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(ide);

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

  it('does not render panel right when no files open', () => {
    expect(vm.$el.querySelector('.panel-right')).toBeNull();
  });

  it('renders panel right when files are open', done => {
    vm.$store.state.trees['abcproject/mybranch'] = {
      tree: [file()],
    };

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.panel-right')).toBeNull();

      done();
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
  });
});
