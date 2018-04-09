import Vue from 'vue';
import store from '~/ide/stores';
import listItem from '~/ide/components/commit_sidebar/list_item.vue';
import router from '~/ide/ide_router';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('Multi-file editor commit sidebar list item', () => {
  let vm;
  let f;

  beforeEach(() => {
    const Component = Vue.extend(listItem);

    f = file('test-file');

    store.state.entries[f.path] = f;

    vm = createComponentWithStore(Component, store, {
      file: f,
      actionComponent: 'stage-button',
    }).$mount();
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(store);
  });

  it('renders file path', () => {
    expect(vm.$el.querySelector('.multi-file-commit-list-path').textContent.trim()).toBe(f.path);
  });

  it('renders actionn button', () => {
    expect(vm.$el.querySelector('.multi-file-discard-btn')).not.toBeNull();
  });

  it('opens a closed file in the editor when clicking the file path', done => {
    spyOn(vm, 'openPendingTab').and.callThrough();
    spyOn(router, 'push');

    vm.$el.querySelector('.multi-file-commit-list-path').click();

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

    vm.$el.querySelector('.multi-file-commit-list-path').click();

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

        expect(vm.iconName).toBe('file-additions');
      });
    });

    describe('iconClass', () => {
      it('returns modified when not a tempFile', () => {
        expect(vm.iconClass).toContain('multi-file-modified');
      });

      it('returns addition when not a tempFile', () => {
        f.tempFile = true;

        expect(vm.iconClass).toContain('multi-file-addition');
      });
    });
  });
});
