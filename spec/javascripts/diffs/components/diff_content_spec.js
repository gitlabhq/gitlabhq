import Vue from 'vue';
import DiffContentComponent from '~/diffs/components/diff_content.vue';
import store from '~/mr_notes/stores';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffContent', () => {
  const Component = Vue.extend(DiffContentComponent);
  let vm;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    vm = mountComponentWithStore(Component, {
      store,
      props: {
        diffFile: getDiffFileMock(),
      },
    });
  });

  describe('text based files', () => {
    it('should render diff inline view', done => {
      vm.$store.state.diffs.diffViewType = 'inline';

      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.js-diff-inline-view').length).toEqual(1);

        done();
      });
    });

    it('should render diff parallel view', done => {
      vm.$store.state.diffs.diffViewType = 'parallel';

      vm.$nextTick(() => {
        expect(vm.$el.querySelectorAll('.parallel').length).toEqual(18);

        done();
      });
    });
  });

  describe('Non-Text diffs', () => {
    beforeEach(() => {
      vm.diffFile.text = false;
    });

    describe('image diff', () => {
      beforeEach(() => {
        vm.diffFile.newPath = GREEN_BOX_IMAGE_URL;
        vm.diffFile.newSha = 'DEF';
        vm.diffFile.oldPath = RED_BOX_IMAGE_URL;
        vm.diffFile.oldSha = 'ABC';
        vm.diffFile.viewPath = '';
      });

      it('should have image diff view in place', done => {
        vm.$nextTick(() => {
          expect(vm.$el.querySelectorAll('.js-diff-inline-view').length).toEqual(0);

          expect(vm.$el.querySelectorAll('.diff-viewer .image').length).toEqual(1);

          done();
        });
      });
    });

    describe('file diff', () => {
      it('should have download buttons in place', done => {
        const el = vm.$el;
        vm.diffFile.newPath = 'test.abc';
        vm.diffFile.newSha = 'DEF';
        vm.diffFile.oldPath = 'test.abc';
        vm.diffFile.oldSha = 'ABC';

        vm.$nextTick(() => {
          expect(el.querySelectorAll('.js-diff-inline-view').length).toEqual(0);

          expect(el.querySelector('.deleted .file-info').textContent.trim()).toContain('test.abc');
          expect(el.querySelector('.deleted .btn.btn-default').textContent.trim()).toContain(
            'Download',
          );

          expect(el.querySelector('.added .file-info').textContent.trim()).toContain('test.abc');
          expect(el.querySelector('.added .btn.btn-default').textContent.trim()).toContain(
            'Download',
          );

          done();
        });
      });
    });
  });
});
