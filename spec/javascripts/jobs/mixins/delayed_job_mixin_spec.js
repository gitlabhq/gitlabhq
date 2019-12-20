import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import delayedJobMixin from '~/jobs/mixins/delayed_job_mixin';

describe('DelayedJobMixin', () => {
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');
  const dummyComponent = Vue.extend({
    mixins: [delayedJobMixin],
    props: {
      job: {
        type: Object,
        required: true,
      },
    },
    template: '<div>{{ remainingTime }}</div>',
  });

  let vm;

  beforeEach(() => {
    jasmine.clock().install();
  });

  afterEach(() => {
    vm.$destroy();
    jasmine.clock().uninstall();
  });

  describe('if job is empty object', () => {
    beforeEach(() => {
      vm = mountComponent(dummyComponent, {
        job: {},
      });
    });

    it('sets remaining time to 00:00:00', () => {
      expect(vm.$el.innerText).toBe('00:00:00');
    });

    describe('after mounting', () => {
      beforeEach(done => {
        Vue.nextTick()
          .then(done)
          .catch(done.fail);
      });

      it('doe not update remaining time', () => {
        expect(vm.$el.innerText).toBe('00:00:00');
      });
    });
  });

  describe('if job is delayed job', () => {
    let remainingTimeInMilliseconds = 42000;

    beforeEach(() => {
      spyOn(Date, 'now').and.callFake(
        () => new Date(delayedJobFixture.scheduled_at).getTime() - remainingTimeInMilliseconds,
      );
      vm = mountComponent(dummyComponent, {
        job: delayedJobFixture,
      });
    });

    it('sets remaining time to 00:00:00', () => {
      expect(vm.$el.innerText).toBe('00:00:00');
    });

    describe('after mounting', () => {
      beforeEach(done => {
        Vue.nextTick()
          .then(done)
          .catch(done.fail);
      });

      it('sets remaining time', () => {
        expect(vm.$el.innerText).toBe('00:00:42');
      });

      it('updates remaining time', done => {
        remainingTimeInMilliseconds = 41000;
        jasmine.clock().tick(1000);

        Vue.nextTick()
          .then(() => {
            expect(vm.$el.innerText).toBe('00:00:41');
          })
          .then(done)
          .catch(done.fail);
      });
    });
  });
});
