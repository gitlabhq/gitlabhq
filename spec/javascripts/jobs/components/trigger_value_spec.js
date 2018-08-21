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
        shortToken: '0a666b2',
      });

      expect(vm.$el.querySelector('.js-short-token').textContent).toContain('0a666b2');
    });
  });

  describe('without short token', () => {
    it('does not render short token', () => {
      vm = mountComponent(Component, {});

      expect(vm.$el.querySelector('.js-short-token')).toBeNull();
    });
  });

  describe('with variables', () => {
    describe('reveal variables', () => {
      it('reveals variables on click', done => {
        vm = mountComponent(Component, {
          variables: {
            key: 'value',
            variable: 'foo',
          },
        });

        vm.$el.querySelector('.js-reveal-variables').click();

        vm
          .$nextTick()
          .then(() => {
            expect(vm.$el.querySelector('.js-build-variables')).not.toBeNull();
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('key');
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('value');
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('variable');
            expect(vm.$el.querySelector('.js-build-variables').textContent).toContain('foo');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });

  describe('without variables', () => {
    it('does not render variables', () => {
      vm = mountComponent(Component);

      expect(vm.$el.querySelector('.js-reveal-variables')).toBeNull();
      expect(vm.$el.querySelector('.js-build-variables')).toBeNull();
    });
  });
});
