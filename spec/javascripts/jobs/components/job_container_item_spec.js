import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import JobContainerItem from '~/jobs/components/job_container_item.vue';
import job from '../mock_data';

describe('JobContainerItem', () => {
  const delayedJobFixture = getJSONFixture('jobs/delayed.json');
  const Component = Vue.extend(JobContainerItem);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  const sharedTests = () => {
    it('displays a status icon', () => {
      expect(vm.$el).toHaveSpriteIcon(job.status.icon);
    });

    it('displays the job name', () => {
      expect(vm.$el).toContainText(job.name);
    });

    it('displays a link to the job', () => {
      const link = vm.$el.querySelector('.js-job-link');

      expect(link.href).toBe(job.status.details_path);
    });
  };

  describe('when a job is not active and not retied', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        job,
        isActive: false,
      });
    });

    sharedTests();
  });

  describe('when a job is active', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        job,
        isActive: true,
      });
    });

    sharedTests();

    it('displays an arrow', () => {
      expect(vm.$el).toHaveSpriteIcon('arrow-right');
    });
  });

  describe('when a job is retried', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        job: {
          ...job,
          retried: true,
        },
        isActive: false,
      });
    });

    sharedTests();

    it('displays an icon', () => {
      expect(vm.$el).toHaveSpriteIcon('retry');
    });
  });

  describe('for delayed job', () => {
    beforeEach(() => {
      const remainingMilliseconds = 1337000;
      spyOn(Date, 'now').and.callFake(
        () => new Date(delayedJobFixture.scheduled_at).getTime() - remainingMilliseconds,
      );
    });

    it('displays remaining time in tooltip', done => {
      vm = mountComponent(Component, {
        job: delayedJobFixture,
        isActive: false,
      });

      Vue.nextTick()
        .then(() => {
          expect(vm.$el.querySelector('.js-job-link').getAttribute('data-original-title')).toEqual(
            'delayed job - delayed manual action (00:22:17)',
          );
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
