import Vue from 'vue';
import DiffFileComponent from '~/diffs/components/diff_file.vue';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffFile', () => {
  let vm;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    vm = createComponentWithStore(Vue.extend(DiffFileComponent), store, {
      file: getDiffFileMock(),
      canCurrentUserFork: false,
    }).$mount();
  });

  describe('template', () => {
    it('should render component with file header, file content components', () => {
      const el = vm.$el;
      const { fileHash, filePath } = diffFileMockData;

      expect(el.id).toEqual(fileHash);
      expect(el.classList.contains('diff-file')).toEqual(true);

      expect(el.querySelectorAll('.diff-content.hidden').length).toEqual(0);
      expect(el.querySelector('.js-file-title')).toBeDefined();
      expect(el.querySelector('.file-title-name').innerText.indexOf(filePath) > -1).toEqual(true);
      expect(el.querySelector('.js-syntax-highlight')).toBeDefined();

      expect(vm.file.renderIt).toEqual(false);
      vm.file.renderIt = true;

      vm.$nextTick(() => {
        expect(el.querySelectorAll('.line_content').length > 5).toEqual(true);
      });
    });

    describe('collapsed', () => {
      it('should not have file content', done => {
        expect(vm.$el.querySelectorAll('.diff-content').length).toEqual(1);
        expect(vm.file.collapsed).toEqual(false);
        vm.file.collapsed = true;
        vm.file.renderIt = true;

        vm.$nextTick(() => {
          expect(vm.$el.querySelectorAll('.diff-content').length).toEqual(0);

          done();
        });
      });

      it('should have collapsed text and link', done => {
        vm.file.collapsed = true;

        vm.$nextTick(() => {
          expect(vm.$el.innerText).toContain('This diff is collapsed');
          expect(vm.$el.querySelectorAll('.js-click-to-expand').length).toEqual(1);

          done();
        });
      });

      it('should have loading icon while loading a collapsed diffs', done => {
        vm.file.collapsed = true;
        vm.isLoadingCollapsedDiff = true;

        vm.$nextTick(() => {
          expect(vm.$el.querySelectorAll('.diff-content.loading').length).toEqual(1);

          done();
        });
      });
    });
  });

  describe('too large diff', () => {
    it('should have too large warning and blob link', done => {
      const BLOB_LINK = '/file/view/path';
      vm.file.tooLarge = true;
      vm.file.viewPath = BLOB_LINK;

      vm.$nextTick(() => {
        expect(vm.$el.innerText).toContain(
          'This source diff could not be displayed because it is too large',
        );
        expect(vm.$el.querySelector('.js-too-large-diff')).toBeDefined();
        expect(vm.$el.querySelector('.js-too-large-diff a').href.indexOf(BLOB_LINK) > -1).toEqual(
          true,
        );

        done();
      });
    });
  });
});
