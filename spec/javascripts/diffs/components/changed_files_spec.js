import Vue from 'vue';
import { mountComponentWithStore } from 'spec/helpers';
import store from '~/diffs/store';
import ChangedFiles from '~/diffs/components/changed_files.vue';

describe('ChangedFiles', () => {
  const Component = Vue.extend(ChangedFiles);

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-element"></div>
      <div class="js-tabs-affix"></div>
    `);
  });

  describe('with single file added', () => {
    let vm;
    const props = {
      diffFiles: [
        {
          addedLines: 10,
          removedLines: 20,
          blob: {
            path: 'some/code.txt',
          },
          filePath: 'some/code.txt',
        },
      ],
    };

    beforeEach(() => {
      vm = mountComponentWithStore(Component, { props, store });
    });

    it('shows files changes', () => {
      expect(vm.$el).toContainText('1 changed file');
    });

    it('shows file additions and deletions', () => {
      expect(vm.$el).toContainText('10 additions');
      expect(vm.$el).toContainText('20 deletions');
    });
  });
});
