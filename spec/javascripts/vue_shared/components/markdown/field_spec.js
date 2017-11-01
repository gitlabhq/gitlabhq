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
      let writeLink;

      beforeEach(() => {
        spyOn(Vue.http, 'post').and.callFake(() => new Promise((resolve) => {
          resolve({
            json() {
              return {
                body: '<p>markdown preview</p>',
              };
            },
          });
        }));

        previewLink = vm.$el.querySelector('.nav-links li:nth-child(2) a');
        writeLink = vm.$el.querySelector('.nav-links li:nth-child(1) a');
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

      function assertLinks(isWrite) {
        expect(writeLink.parentNode.classList.contains('active')).toEqual(isWrite);
        expect(previewLink.parentNode.classList.contains('active')).toEqual(!isWrite);
        expect(vm.$el.querySelector('.md-preview').style.display).toEqual(isWrite ? 'none' : '');
      }

      it('clicking already active write or preview link does nothing', (done) => {
        writeLink.click();

        setTimeout(() => {
          assertLinks(true);

          writeLink.click();

          setTimeout(() => {
            assertLinks(true);

            previewLink.click();

            setTimeout(() => {
              assertLinks(false);

              previewLink.click();

              setTimeout(() => {
                assertLinks(false);

                done();
              });
            });
          });
        });
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
