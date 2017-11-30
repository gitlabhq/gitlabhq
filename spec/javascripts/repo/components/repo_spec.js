import Vue from 'vue';
import store from '~/repo/stores';
import repo from '~/repo/components/repo.vue';
import { createComponentWithStore } from '../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../helpers';

describe('repo component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(repo);

    vm = createComponentWithStore(Component, store).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('does not render panel right when no files open', () => {
    expect(vm.$el.querySelector('.panel-right')).toBeNull();
  });

  it('renders panel right when files are open', (done) => {
    vm.$store.state.tree.push(file());

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.panel-right')).toBeNull();

      done();
    });
  });
});
