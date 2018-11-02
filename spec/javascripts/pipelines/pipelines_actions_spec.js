import Vue from 'vue';
import eventHub from '~/pipelines/event_hub';
import PipelinesActions from '~/pipelines/components/pipelines_actions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';

describe('Pipelines Actions dropdown', () => {
  const Component = Vue.extend(PipelinesActions);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('manual actions', () => {
    const actions = [
      {
        name: 'stop_review',
        path: `${TEST_HOST}/root/review-app/builds/1893/play`,
      },
      {
        name: 'foo',
        path: `${TEST_HOST}/disabled/pipeline/action`,
        playable: false,
      },
    ];

    beforeEach(() => {
      vm = mountComponent(Component, { actions });
    });

    it('renders a dropdown with the provided actions', () => {
      const dropdownItems = vm.$el.querySelectorAll('.dropdown-menu li');

      expect(dropdownItems.length).toEqual(actions.length);
    });

    it("renders a disabled action when it's not playable", () => {
      const dropdownItem = vm.$el.querySelector('.dropdown-menu li:last-child button');

      expect(dropdownItem).toBeDisabled();
    });
  });

  describe('scheduled jobs', () => {
    const scheduledJobAction = {
      name: 'scheduled action',
      path: `${TEST_HOST}/scheduled/job/action`,
      playable: true,
      scheduled_at: '2063-04-05T00:42:00Z',
    };
    const expiredJobAction = {
      name: 'expired action',
      path: `${TEST_HOST}/expired/job/action`,
      playable: true,
      scheduled_at: '2018-10-05T08:23:00Z',
    };
    const findDropdownItem = action => {
      const buttons = vm.$el.querySelectorAll('.dropdown-menu li button');
      return Array.prototype.find.call(buttons, element =>
        element.innerText.trim().startsWith(action.name),
      );
    };

    beforeEach(done => {
      spyOn(Date, 'now').and.callFake(() => new Date('2063-04-04T00:42:00Z').getTime());
      vm = mountComponent(Component, { actions: [scheduledJobAction, expiredJobAction] });

      Vue.nextTick()
        .then(done)
        .catch(done.fail);
    });

    it('emits postAction event after confirming', () => {
      const emitSpy = jasmine.createSpy('emit');
      eventHub.$on('postAction', emitSpy);
      spyOn(window, 'confirm').and.callFake(() => true);

      findDropdownItem(scheduledJobAction).click();

      expect(window.confirm).toHaveBeenCalled();
      expect(emitSpy).toHaveBeenCalledWith(scheduledJobAction.path);
    });

    it('does not emit postAction event if confirmation is cancelled', () => {
      const emitSpy = jasmine.createSpy('emit');
      eventHub.$on('postAction', emitSpy);
      spyOn(window, 'confirm').and.callFake(() => false);

      findDropdownItem(scheduledJobAction).click();

      expect(window.confirm).toHaveBeenCalled();
      expect(emitSpy).not.toHaveBeenCalled();
    });

    it('displays the remaining time in the dropdown', () => {
      expect(findDropdownItem(scheduledJobAction)).toContainText('24:00:00');
    });

    it('displays 00:00:00 for expired jobs in the dropdown', () => {
      expect(findDropdownItem(expiredJobAction)).toContainText('00:00:00');
    });
  });
});
