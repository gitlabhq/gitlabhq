import mountComponent from 'spec/helpers/vue_mount_component_helper';
import Vue from 'vue';
import GlCountdown from '~/vue_shared/components/gl_countdown.vue';

describe('GlCountdown', () => {
  const Component = Vue.extend(GlCountdown);
  let vm;
  let now = '2000-01-01T00:00:00Z';

  beforeEach(() => {
    spyOn(Date, 'now').and.callFake(() => new Date(now).getTime());
    jasmine.clock().install();
  });

  afterEach(() => {
    vm.$destroy();
    jasmine.clock().uninstall();
  });

  describe('when there is time remaining', () => {
    beforeEach(done => {
      vm = mountComponent(Component, {
        endDateString: '2000-01-01T01:02:03Z',
      });

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('displays remaining time', () => {
      expect(vm.$el).toContainText('01:02:03');
    });

    it('updates remaining time', done => {
      now = '2000-01-01T00:00:01Z';
      jasmine.clock().tick(1000);

      Vue.nextTick()
        .then(() => {
          expect(vm.$el).toContainText('01:02:02');
          done();
        })
        .catch(done.fail);
    });
  });

  describe('when there is no time remaining', () => {
    beforeEach(done => {
      vm = mountComponent(Component, {
        endDateString: '1900-01-01T00:00:00Z',
      });

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('displays 00:00:00', () => {
      expect(vm.$el).toContainText('00:00:00');
    });
  });

  describe('when an invalid date is passed', () => {
    it('throws a validation error', () => {
      spyOn(Vue.config, 'warnHandler').and.stub();
      vm = mountComponent(Component, {
        endDateString: 'this is invalid',
      });

      expect(Vue.config.warnHandler).toHaveBeenCalledTimes(1);
      const [errorMessage] = Vue.config.warnHandler.calls.argsFor(0);

      expect(errorMessage).toMatch(/^Invalid prop: .* "endDateString"/);
    });
  });
});
