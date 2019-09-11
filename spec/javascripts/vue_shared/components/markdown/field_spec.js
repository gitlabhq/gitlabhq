import $ from 'jquery';
import '~/behaviors/markdown/render_gfm';
import Vue from 'vue';
import AxiosMockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import fieldComponent from '~/vue_shared/components/markdown/field.vue';
import { TEST_HOST } from 'spec/test_constants';

function assertMarkdownTabs(isWrite, writeLink, previewLink, vm) {
  expect(writeLink.parentNode.classList.contains('active')).toEqual(isWrite);
  expect(previewLink.parentNode.classList.contains('active')).toEqual(!isWrite);
  expect(vm.$el.querySelector('.md-preview-holder').style.display).toEqual(isWrite ? 'none' : '');
}

describe('Markdown field component', () => {
  const markdownPreviewPath = `${TEST_HOST}/preview`;
  const markdownDocsPath = `${TEST_HOST}/docs`;
  let axiosMock;
  let vm;

  beforeEach(done => {
    axiosMock = new AxiosMockAdapter(axios);
    vm = new Vue({
      components: {
        fieldComponent,
      },
      data() {
        return {
          text: 'testing\n123',
        };
      },
      template: `
        <field-component
          markdown-preview-path="${markdownPreviewPath}"
          markdown-docs-path="${markdownDocsPath}"
        >
          <textarea
            slot="textarea"
            v-model="text">
          </textarea>
        </field-component>
      `,
    }).$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    axiosMock.restore();
  });

  describe('mounted', () => {
    const previewHTML = '<p>markdown preview</p>';

    it('renders textarea inside backdrop', () => {
      expect(vm.$el.querySelector('.zen-backdrop textarea')).not.toBeNull();
    });

    describe('markdown preview', () => {
      let previewLink;
      let writeLink;

      beforeEach(() => {
        axiosMock.onPost(markdownPreviewPath).replyOnce(200, { body: previewHTML });

        previewLink = vm.$el.querySelector('.nav-links .js-preview-link');
        writeLink = vm.$el.querySelector('.nav-links .js-write-link');
      });

      it('sets preview link as active', done => {
        previewLink.click();

        Vue.nextTick(() => {
          expect(previewLink.parentNode.classList.contains('active')).toBeTruthy();

          done();
        });
      });

      it('shows preview loading text', done => {
        previewLink.click();

        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.md-preview-holder').textContent.trim()).toContain(
            'Loading…',
          );

          done();
        });
      });

      it('renders markdown preview', done => {
        previewLink.click();

        setTimeout(() => {
          expect(vm.$el.querySelector('.md-preview-holder').innerHTML).toContain(previewHTML);

          done();
        });
      });

      it('renders GFM with jQuery', done => {
        spyOn($.fn, 'renderGFM');

        previewLink.click();

        setTimeout(() => {
          expect($.fn.renderGFM).toHaveBeenCalled();

          done();
        }, 0);
      });

      it('clicking already active write or preview link does nothing', done => {
        writeLink.click();
        Vue.nextTick()
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, vm))
          .then(() => writeLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(true, writeLink, previewLink, vm))
          .then(() => previewLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, vm))
          .then(() => previewLink.click())
          .then(() => Vue.nextTick())
          .then(() => assertMarkdownTabs(false, writeLink, previewLink, vm))
          .then(done)
          .catch(done.fail);
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', done => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 7);
        vm.$el.querySelector('.js-md').click();

        Vue.nextTick(() => {
          expect(textarea.value).toContain('**testing**');

          done();
        });
      });

      it('converts a line', done => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 0);
        vm.$el.querySelectorAll('.js-md')[5].click();

        Vue.nextTick(() => {
          expect(textarea.value).toContain('*  testing');

          done();
        });
      });

      it('converts multiple lines', done => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 50);
        vm.$el.querySelectorAll('.js-md')[5].click();

        Vue.nextTick(() => {
          expect(textarea.value).toContain('* testing\n* 123');

          done();
        });
      });
    });
  });
});
