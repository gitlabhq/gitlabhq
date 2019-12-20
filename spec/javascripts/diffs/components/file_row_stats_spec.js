import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import FileRowStats from '~/diffs/components/file_row_stats.vue';

describe('Diff file row stats', () => {
  let Component;
  let vm;

  beforeAll(() => {
    Component = Vue.extend(FileRowStats);
  });

  beforeEach(() => {
    vm = mountComponent(Component, {
      file: {
        addedLines: 20,
        removedLines: 10,
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders added lines count', () => {
    expect(vm.$el.querySelector('.cgreen').textContent).toContain('+20');
  });

  it('renders removed lines count', () => {
    expect(vm.$el.querySelector('.cred').textContent).toContain('-10');
  });
});
