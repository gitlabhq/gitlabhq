import Vue from 'vue';
import { mountComponent } from 'spec/helpers';
import ChangedFiles from '~/diffs/components/changed_files.vue';

const vueMatchers = {
  toContainText() {
    return {
      compare(vm, text) {
        const result = {
          pass: vm.$el.innerText.includes(text),
        };
        return result;
      },
    };
  },
  toRender() {
    return {
      compare(vm) {
        const result = {
          pass: vm.$el.nodeType !== Node.COMMENT_NODE,
        };
        return result;
      },
    };
  },
};

describe('ChangedFiles', () => {
  const Component = Vue.extend(ChangedFiles);

  beforeEach(() => {
    jasmine.addMatchers(vueMatchers);
  });

  describe('with no changed files', () => {
    const props = {
      diffFiles: [],
    };

    it('does not render', () => {
      const vm = mountComponent(Component, props);

      expect(vm).not.toRender();
    });
  });

  describe('with single file added', () => {
    let vm;
    const props = {
      diffFiles: [{
        addedLines: 10,
        removedLines: 20,
      }],
    };

    beforeEach(() => {
      vm = mountComponent(Component, props);
    });

    it('shows files changes', () => {
      expect(vm).toContainText('1 changed file');
    });

    it('shows file additions and deletions', () => {
      expect(vm).toContainText('10 additions');
      expect(vm).toContainText('20 deletions');
    });
  });
});
