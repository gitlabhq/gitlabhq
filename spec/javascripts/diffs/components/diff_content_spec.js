import Vue from 'vue';
import DiffContentComponent from '~/diffs/components/diff_content.vue';
import { createStore } from '~/mr_notes/stores';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { GREEN_BOX_IMAGE_URL, RED_BOX_IMAGE_URL } from 'spec/test_constants';
import '~/behaviors/markdown/render_gfm';
import diffFileMockData from '../mock_data/diff_file';
import discussionsMockData from '../mock_data/diff_discussions';

describe('DiffContent', () => {
  const Component = Vue.extend(DiffContentComponent);
  let vm;

  beforeEach(() => {
    const store = createStore();
    store.state.notes.noteableData = {
      current_user: {
        can_create_note: false,
      },
    };

    vm = mountComponentWithStore(Component, {
      store,
      props: {
        diffFile: JSON.parse(JSON.stringify(diffFileMockData)),
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
      vm.diffFile.viewer.name = 'image';
    });

    describe('image diff', () => {
      beforeEach(done => {
        vm.diffFile.newPath = GREEN_BOX_IMAGE_URL;
        vm.diffFile.newSha = 'DEF';
        vm.diffFile.oldPath = RED_BOX_IMAGE_URL;
        vm.diffFile.oldSha = 'ABC';
        vm.diffFile.viewPath = '';
        vm.diffFile.discussions = [{ ...discussionsMockData }];
        vm.$store.state.diffs.commentForms.push({
          fileHash: vm.diffFile.fileHash,
          x: 10,
          y: 20,
          width: 100,
          height: 200,
        });

        vm.$nextTick(done);
      });

      it('should have image diff view in place', () => {
        expect(vm.$el.querySelectorAll('.js-diff-inline-view').length).toEqual(0);

        expect(vm.$el.querySelectorAll('.diff-viewer .image').length).toEqual(1);
      });

      it('renders image diff overlay', () => {
        expect(vm.$el.querySelector('.image-diff-overlay')).not.toBe(null);
      });

      it('renders diff file discussions', () => {
        expect(vm.$el.querySelectorAll('.discussion .note.timeline-entry').length).toEqual(5);
      });

      describe('handleSaveNote', () => {
        it('dispatches handleSaveNote', () => {
          spyOn(vm.$store, 'dispatch').and.stub();

          vm.handleSaveNote('test');

          expect(vm.$store.dispatch).toHaveBeenCalledWith('diffs/saveDiffDiscussion', {
            note: 'test',
            formData: {
              noteableData: jasmine.anything(),
              noteableType: jasmine.anything(),
              diffFile: vm.diffFile,
              positionType: 'image',
              x: 10,
              y: 20,
              width: 100,
              height: 200,
            },
          });
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
