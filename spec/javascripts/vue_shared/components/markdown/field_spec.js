import Vue from 'vue';
import fieldComponent from '~/vue_shared/components/markdown/field.vue';

describe('Markdown field component', () => {
  let vm;

  beforeEach(() => {
    vm = new Vue({
      render(createElement) {
        return createElement(
          fieldComponent,
          {
            props: {
              markdownPreviewUrl: '/preview',
              markdownDocs: '/docs',
            },
          },
          [
            createElement('textarea', {
              slot: 'textarea',
            }),
          ],
        );
      },
    });
  });

  it('creates a new instance of GL form', (done) => {
    spyOn(gl, 'GLForm');
    vm.$mount();

    Vue.nextTick(() => {
      expect(
        gl.GLForm,
      ).toHaveBeenCalled();

      done();
    });
  });

  describe('mounted', () => {
    beforeEach((done) => {
      vm.$mount();

      Vue.nextTick(done);
    });

    it('renders textarea inside backdrop', () => {
      expect(
        vm.$el.querySelector('.zen-backdrop textarea'),
      ).not.toBeNull();
    });

    describe('markdown preview', () => {
      let previewLink;

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
        });
      });
    });
  });
});
