import Vue from 'vue';
import { trimText } from 'spec/helpers/text_helper';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import store from '~/ide/stores';
import listItem from '~/ide/components/commit_sidebar/list_item.vue';
import router from '~/ide/ide_router';
import { file, resetStore } from '../../helpers';

describe('Multi-file editor commit sidebar list item', () => {
  let vm;
  let f;
  let findPathEl;

  beforeEach(() => {
    const Component = Vue.extend(listItem);

    f = file('test-file');

    store.state.entries[f.path] = f;

    vm = createComponentWithStore(Component, store, {
      file: f,
      actionComponent: 'stage-button',
      activeFileKey: `staged-${f.key}`,
    }).$mount();

    findPathEl = vm.$el.querySelector('.multi-file-commit-list-path');
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(store);
  });

  const findPathText = () => trimText(findPathEl.textContent);

  it('renders file path', () => {
    expect(findPathText()).toContain(f.path);
  });

  it('correctly renders renamed entries', done => {
    Vue.set(vm.file, 'prevName', 'Old name');

    vm.$nextTick()
      .then(() => {
        expect(findPathText()).toEqual(`Old name → ${f.name}`);
      })
      .then(done)
      .catch(done.fail);
  });

  it('correctly renders entry, the name of which did not change after rename (as within a folder)', done => {
    Vue.set(vm.file, 'prevName', f.name);

    vm.$nextTick()
      .then(() => {
        expect(findPathText()).toEqual(f.name);
      })
      .then(done)
      .catch(done.fail);
  });

  it('opens a closed file in the editor when clicking the file path', done => {
    spyOn(vm, 'openPendingTab').and.callThrough();
    spyOn(router, 'push');

    findPathEl.click();

    setTimeout(() => {
      expect(vm.openPendingTab).toHaveBeenCalled();
      expect(router.push).toHaveBeenCalled();

      done();
    });
  });

  it('calls updateViewer with diff when clicking file', done => {
    spyOn(vm, 'openFileInEditor').and.callThrough();
    spyOn(vm, 'updateViewer').and.callThrough();
    spyOn(router, 'push');

    findPathEl.click();

    setTimeout(() => {
      expect(vm.updateViewer).toHaveBeenCalledWith('diff');

      done();
    });
  });

  describe('computed', () => {
    describe('iconName', () => {
      it('returns modified when not a tempFile', () => {
        expect(vm.iconName).toBe('file-modified');
      });

      it('returns addition when not a tempFile', () => {
        f.tempFile = true;

        expect(vm.iconName).toBe('file-addition');
      });

      it('returns deletion', () => {
        f.deleted = true;

        expect(vm.iconName).toBe('file-deletion');
      });
    });

    describe('iconClass', () => {
      it('returns modified when not a tempFile', () => {
        expect(vm.iconClass).toContain('ide-file-modified');
      });

      it('returns addition when not a tempFile', () => {
        f.tempFile = true;

        expect(vm.iconClass).toContain('ide-file-addition');
      });

      it('returns deletion', () => {
        f.deleted = true;

        expect(vm.iconClass).toContain('ide-file-deletion');
      });
    });
  });

  describe('is active', () => {
    it('does not add active class when dont keys match', () => {
      expect(vm.$el.querySelector('.is-active')).toBe(null);
    });

    it('adds active class when keys match', done => {
      vm.keyPrefix = 'staged';

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.is-active')).not.toBe(null);

        done();
      });
    });
  });
});
