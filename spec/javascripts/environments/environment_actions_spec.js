import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import eventHub from '~/environments/event_hub';
import EnvironmentActions from '~/environments/components/environment_actions.vue';

describe('EnvironmentActions Component', () => {
  const Component = Vue.extend(EnvironmentActions);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('manual actions', () => {
    const actions = [
      {
        name: 'bar',
        play_path: 'https://gitlab.com/play',
      },
      {
        name: 'foo',
        play_path: '#',
      },
      {
        name: 'foo bar',
        play_path: 'url',
        playable: false,
      },
    ];

    beforeEach(() => {
      vm = mountComponent(Component, { actions });
    });

    it('should render a dropdown button with icon and title attribute', () => {
      expect(vm.$el.querySelector('.fa-caret-down')).toBeDefined();
      expect(vm.$el.querySelector('.dropdown-new').getAttribute('data-original-title')).toEqual(
        'Deploy to...',
      );

      expect(vm.$el.querySelector('.dropdown-new').getAttribute('aria-label')).toEqual(
        'Deploy to...',
      );
    });

    it('should render a dropdown with the provided list of actions', () => {
      expect(vm.$el.querySelectorAll('.dropdown-menu li').length).toEqual(actions.length);
    });

    it("should render a disabled action when it's not playable", () => {
      expect(
        vm.$el.querySelector('.dropdown-menu li:last-child button').getAttribute('disabled'),
      ).toEqual('disabled');

      expect(
        vm.$el.querySelector('.dropdown-menu li:last-child button').classList.contains('disabled'),
      ).toEqual(true);
    });
  });

  describe('scheduled jobs', () => {
    const scheduledJobAction = {
      name: 'scheduled action',
      playPath: `${TEST_HOST}/scheduled/job/action`,
      playable: true,
      scheduledAt: '2063-04-05T00:42:00Z',
    };
    const expiredJobAction = {
      name: 'expired action',
      playPath: `${TEST_HOST}/expired/job/action`,
      playable: true,
      scheduledAt: '2018-10-05T08:23:00Z',
    };
    const findDropdownItem = action => {
      const buttons = vm.$el.querySelectorAll('.dropdown-menu li button');
      return Array.prototype.find.call(buttons, element =>
        element.innerText.trim().startsWith(action.name),
      );
    };

    beforeEach(() => {
      spyOn(Date, 'now').and.callFake(() => new Date('2063-04-04T00:42:00Z').getTime());
      vm = mountComponent(Component, { actions: [scheduledJobAction, expiredJobAction] });
    });

    it('emits postAction event after confirming', () => {
      const emitSpy = jasmine.createSpy('emit');
      eventHub.$on('postAction', emitSpy);
      spyOn(window, 'confirm').and.callFake(() => true);

      findDropdownItem(scheduledJobAction).click();

      expect(window.confirm).toHaveBeenCalled();
      expect(emitSpy).toHaveBeenCalledWith({ endpoint: scheduledJobAction.playPath });
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
