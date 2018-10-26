import Vue from 'vue';
import component from '~/jobs/components/trigger_block.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Trigger block', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with short token', () => {
    it('renders short token', () => {
      vm = mountComponent(Component, {
        trigger: {
          short_token: '0a666b2',
        },
      });

      expect(vm.$el.querySelector('.js-short-token').textContent).toContain('0a666b2');
    });
  });

  describe('without short token', () => {
    it('does not render short token', () => {
      vm = mountComponent(Component, { trigger: {} });

      expect(vm.$el.querySelector('.js-short-token')).toBeNull();
    });
  });

  describe('with variables', () => {
    describe('reveal variables', () => {
      it('reveals variables on click', done => {
        vm = mountComponent(Component, {
          trigger: {
            short_token: 'bd7e',
            variables: [
              { key: 'UPLOAD_TO_GCS', value: 'false', public: false },
              { key: 'UPLOAD_TO_S3', value: 'true', public: false },
            ],
          },
        });

        vm.$el.querySelector('.js-reveal-variables').click();

        vm.$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-build-variables')).not.toBeNull();
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain(
              'UPLOAD_TO_GCS',
            );

            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('false');
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain(
              'UPLOAD_TO_S3',
            );

            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('true');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('without variables', () => {
    it('does not render variables', () => {
      vm = mountComponent(Component, { trigger: {} });

      expect(vm.$el.querySelector('.js-reveal-variables')).toBeNull();
      expect(vm.$el.querySelector('.js-build-variables')).toBeNull();
    });
  });
});
