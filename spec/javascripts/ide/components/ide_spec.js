import Vue from 'vue';
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
});
