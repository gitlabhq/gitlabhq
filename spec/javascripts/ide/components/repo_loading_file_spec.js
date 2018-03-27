import Vue from 'vue';
import store from '~/ide/stores';
import repoLoadingFile from '~/ide/components/repo_loading_file.vue';
import { resetStore } from '../helpers';

describe('RepoLoadingFile', () => {
  let vm;

  function createComponent() {
    const RepoLoadingFile = Vue.extend(repoLoadingFile);

    return new RepoLoadingFile({
      store,
    }).$mount();
  }

  function assertLines(lines) {
    lines.forEach((line, n) => {
      const index = n + 1;
      expect(line.classList.contains(`skeleton-line-${index}`)).toBeTruthy();
    });
  }

  function assertColumns(columns) {
    columns.forEach(column => {
      const container = column.querySelector('.animation-container');
      const lines = [...container.querySelectorAll(':scope > div')];

      expect(container).toBeTruthy();
      expect(lines.length).toEqual(6);
      assertLines(lines);
    });
  }

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders 3 columns of animated LoC', () => {
    vm = createComponent();
    const columns = [...vm.$el.querySelectorAll('td')];

    expect(columns.length).toEqual(3);
    assertColumns(columns);
  });

  it('renders 1 column of animated LoC if isMini', done => {
    vm = createComponent();
    vm.$store.state.leftPanelCollapsed = true;
    vm.$store.state.openFiles.push('test');

    vm.$nextTick(() => {
      const columns = [...vm.$el.querySelectorAll('td')];

      expect(columns.length).toEqual(1);
      assertColumns(columns);

      done();
    });
  });
});
