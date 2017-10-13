import Vue from 'vue';
import RepoStore from '~/repo/stores/repo_store';
import repoLoadingFile from '~/repo/components/repo_loading_file.vue';

describe('RepoLoadingFile', () => {
  function createComponent(propsData) {
    const RepoLoadingFile = Vue.extend(repoLoadingFile);

    return new RepoLoadingFile({
      propsData,
    }).$mount();
  }

  function assertLines(lines) {
    lines.forEach((line, n) => {
      const index = n + 1;
      expect(line.classList.contains(`skeleton-line-${index}`)).toBeTruthy();
    });
  }

  function assertColumns(columns) {
    columns.forEach((column) => {
      const container = column.querySelector('.animation-container');
      const lines = [...container.querySelectorAll(':scope > div')];

      expect(container).toBeTruthy();
      expect(lines.length).toEqual(6);
      assertLines(lines);
    });
  }

  afterEach(() => {
    RepoStore.openedFiles = [];
  });

  it('renders 3 columns of animated LoC', () => {
    const vm = createComponent({
      loading: {
        tree: true,
      },
      hasFiles: false,
    });
    const columns = [...vm.$el.querySelectorAll('td')];

    expect(columns.length).toEqual(3);
    assertColumns(columns);
  });

  it('renders 1 column of animated LoC if isMini', () => {
    RepoStore.openedFiles = new Array(1);
    const vm = createComponent({
      loading: {
        tree: true,
      },
      hasFiles: false,
    });
    const columns = [...vm.$el.querySelectorAll('td')];

    expect(columns.length).toEqual(1);
    assertColumns(columns);
  });
});
