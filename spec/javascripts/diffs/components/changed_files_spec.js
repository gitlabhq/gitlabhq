import Vue from 'vue';
import $ from 'jquery';
import { mountComponentWithStore } from 'spec/helpers';
import store from '~/diffs/store';
import ChangedFiles from '~/diffs/components/changed_files.vue';

describe('ChangedFiles', () => {
  const Component = Vue.extend(ChangedFiles);
  const createComponent = props => mountComponentWithStore(Component, { props, store });
  let vm;

  beforeEach(() => {
    setFixtures(`
      <div id="dummy-element"></div>
      <div class="js-tabs-affix"></div>
    `);
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
    vm = createComponent(props);
  });

  describe('with single file added', () => {
    it('shows files changes', () => {
      expect(vm.$el).toContainText('1 changed file');
    });

    it('shows file additions and deletions', () => {
      expect(vm.$el).toContainText('10 additions');
      expect(vm.$el).toContainText('20 deletions');
    });
  });

  describe('template', () => {
    describe('diff view mode buttons', () => {
      let inlineButton;
      let parallelButton;

      beforeEach(() => {
        inlineButton = vm.$el.querySelector('.js-inline-diff-button');
        parallelButton = vm.$el.querySelector('.js-parallel-diff-button');
      });

      it('should have Inline and Side-by-side buttons', () => {
        expect(inlineButton).toBeDefined();
        expect(parallelButton).toBeDefined();
      });

      it('should add active class to Inline button', done => {
        vm.$store.state.diffs.diffViewType = 'inline';

        vm.$nextTick(() => {
          expect(inlineButton.classList.contains('active')).toEqual(true);
          expect(parallelButton.classList.contains('active')).toEqual(false);

          done();
        });
      });

      it('should toggle active state of buttons when diff view type changed', done => {
        vm.$store.state.diffs.diffViewType = 'parallel';

        vm.$nextTick(() => {
          expect(inlineButton.classList.contains('active')).toEqual(false);
          expect(parallelButton.classList.contains('active')).toEqual(true);

          done();
        });
      });

      describe('clicking them', () => {
        it('should toggle the diff view type', done => {
          $(parallelButton).click();

          vm.$nextTick(() => {
            expect(inlineButton.classList.contains('active')).toEqual(false);
            expect(parallelButton.classList.contains('active')).toEqual(true);

            $(inlineButton).click();

            vm.$nextTick(() => {
              expect(inlineButton.classList.contains('active')).toEqual(true);
              expect(parallelButton.classList.contains('active')).toEqual(false);
              done();
            });
          });
        });
      });
    });
  });
});
