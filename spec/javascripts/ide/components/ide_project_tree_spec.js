import Vue from 'vue';
import ProjectTree from '~/ide/components/ide_project_tree.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('IDE project tree', () => {
  const Component = Vue.extend(ProjectTree);
  let vm;

  beforeEach(() => {
    vm = createComponent(Component, {
      project: {
        id: 1,
        name: 'test',
        web_url: gl.TEST_HOST,
        avatar_url: '',
        branches: [],
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders identicon when projct has no avatar', () => {
    expect(vm.$el.querySelector('.identicon')).not.toBeNull();
  });

  it('renders avatar image if project has avatar', done => {
    vm.project.avatar_url = gl.TEST_HOST;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.identicon')).toBeNull();
      expect(vm.$el.querySelector('img.avatar')).not.toBeNull();

      done();
    });
  });
});
