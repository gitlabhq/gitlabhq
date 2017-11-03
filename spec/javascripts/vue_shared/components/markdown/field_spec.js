import Vue from 'vue';
import fieldComponent from '~/vue_shared/components/markdown/field.vue';

describe('Markdown field component', () => {
  let vm;

  beforeEach((done) => {
    vm = new Vue({
      data() {
        return {
          text: 'testing\n123',
        };
      },
      components: {
        fieldComponent,
      },
      template: `
        <field-component
          markdown-preview-path="/preview"
          markdown-docs-path="/docs"
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

  describe('mounted', () => {
    it('renders textarea inside backdrop', () => {
      expect(
        vm.$el.querySelector('.zen-backdrop textarea'),
      ).not.toBeNull();
    });

    describe('markdown preview', () => {
      let previewLink;

      beforeEach(() => {
        spyOn(Vue.http, 'post').and.callFake(() => new Promise((resolve) => {
          setTimeout(() => {
            resolve({
              json() {
                return {
                  body: '<p>markdown preview</p>',
                };
              },
            });
          });
        }));

        previewLink = vm.$el.querySelector('.nav-links li:nth-child(2) a');
      });

      it('sets preview link as active', (done) => {
        previewLink.click();

        Vue.nextTick(() => {
          expect(
            previewLink.parentNode.classList.contains('active'),
          ).toBeTruthy();

          done();
        });
      });

      it('shows preview loading text', (done) => {
        previewLink.click();

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector('.md-preview').textContent.trim(),
          ).toContain('Loading...');

          done();
        });
      });

      it('renders markdown preview', (done) => {
        previewLink.click();

        setTimeout(() => {
          expect(
            vm.$el.querySelector('.md-preview').innerHTML,
          ).toContain('<p>markdown preview</p>');

          done();
        });
      });

      it('renders GFM with jQuery', (done) => {
        spyOn($.fn, 'renderGFM');

        previewLink.click();

        setTimeout(() => {
          expect(
            $.fn.renderGFM,
          ).toHaveBeenCalled();

          done();
        }, 0);
      });
    });

    describe('markdown buttons', () => {
      it('converts single words', (done) => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 7);
        vm.$el.querySelector('.js-md').click();

        Vue.nextTick(() => {
          expect(
            textarea.value,
          ).toContain('**testing**');

          done();
        });
      });

      it('converts a line', (done) => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 0);
        vm.$el.querySelectorAll('.js-md')[4].click();

        Vue.nextTick(() => {
          expect(
            textarea.value,
          ).toContain('*  testing');

          done();
        });
      });

      it('converts multiple lines', (done) => {
        const textarea = vm.$el.querySelector('textarea');

        textarea.setSelectionRange(0, 50);
        vm.$el.querySelectorAll('.js-md')[4].click();

        Vue.nextTick(() => {
          expect(
            textarea.value,
          ).toContain('* testing\n* 123');

          done();
        });
      });
    });
  });
});
