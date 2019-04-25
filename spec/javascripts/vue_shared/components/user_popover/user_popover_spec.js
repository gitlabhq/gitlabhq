import Vue from 'vue';
import userPopover from '~/vue_shared/components/user_popover/user_popover.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

const DEFAULT_PROPS = {
  loaded: true,
  user: {
    username: 'root',
    name: 'Administrator',
    location: 'Vienna',
    bio: null,
    organization: null,
    status: null,
  },
};

const UserPopover = Vue.extend(userPopover);

describe('User Popover Component', () => {
  const fixtureTemplate = 'merge_requests/diff_comment.html';
  preloadFixtures(fixtureTemplate);

  let vm;

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Empty', () => {
    beforeEach(() => {
      vm = mountComponent(UserPopover, {
        target: document.querySelector('.js-user-link'),
        user: {
          name: null,
          username: null,
          location: null,
          bio: null,
          organization: null,
          status: null,
        },
      });
    });

    it('should return skeleton loaders', () => {
      expect(vm.$el.querySelectorAll('.animation-container').length).toBe(4);
    });
  });

  describe('basic data', () => {
    it('should show basic fields', () => {
      vm = mountComponent(UserPopover, {
        ...DEFAULT_PROPS,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.textContent).toContain(DEFAULT_PROPS.user.name);
      expect(vm.$el.textContent).toContain(DEFAULT_PROPS.user.username);
      expect(vm.$el.textContent).toContain(DEFAULT_PROPS.user.location);
    });

    it('shows icon for location', () => {
      const iconEl = vm.$el.querySelector('.js-location svg');

      expect(iconEl.querySelector('use').getAttribute('xlink:href')).toContain('location');
    });
  });

  describe('job data', () => {
    it('should show only bio if no organization is available', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.bio = 'Engineer';

      vm = mountComponent(UserPopover, {
        ...testProps,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.textContent).toContain('Engineer');
    });

    it('should show only organization if no bio is available', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.organization = 'GitLab';

      vm = mountComponent(UserPopover, {
        ...testProps,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.textContent).toContain('GitLab');
    });

    it('should display bio and organization in separate lines', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.bio = 'Engineer';
      testProps.user.organization = 'GitLab';

      vm = mountComponent(UserPopover, {
        ...DEFAULT_PROPS,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.querySelector('.js-bio').textContent).toContain('Engineer');
      expect(vm.$el.querySelector('.js-organization').textContent).toContain('GitLab');
    });

    it('should not encode special characters in bio and organization', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.bio = 'Manager & Team Lead';
      testProps.user.organization = 'Me & my <funky> Company';

      vm = mountComponent(UserPopover, {
        ...DEFAULT_PROPS,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.querySelector('.js-bio').textContent).toContain('Manager & Team Lead');
      expect(vm.$el.querySelector('.js-organization').textContent).toContain(
        'Me & my <funky> Company',
      );
    });

    it('shows icon for bio', () => {
      const iconEl = vm.$el.querySelector('.js-bio svg');

      expect(iconEl.querySelector('use').getAttribute('xlink:href')).toContain('profile');
    });

    it('shows icon for organization', () => {
      const iconEl = vm.$el.querySelector('.js-organization svg');

      expect(iconEl.querySelector('use').getAttribute('xlink:href')).toContain('work');
    });
  });

  describe('status data', () => {
    it('should show only message', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.status = { message_html: 'Hello World' };

      vm = mountComponent(UserPopover, {
        ...DEFAULT_PROPS,
        target: document.querySelector('.js-user-link'),
      });

      expect(vm.$el.textContent).toContain('Hello World');
    });

    it('should show message and emoji', () => {
      const testProps = Object.assign({}, DEFAULT_PROPS);
      testProps.user.status = { emoji: 'basketball_player', message_html: 'Hello World' };

      vm = mountComponent(UserPopover, {
        ...DEFAULT_PROPS,
        target: document.querySelector('.js-user-link'),
        status: { emoji: 'basketball_player', message_html: 'Hello World' },
      });

      expect(vm.$el.textContent).toContain('Hello World');
      expect(vm.$el.innerHTML).toContain('<gl-emoji data-name="basketball_player"');
    });
  });
});
