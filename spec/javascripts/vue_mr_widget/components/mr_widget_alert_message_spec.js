import { shallowMount, createLocalVue } from '@vue/test-utils';
import MrWidgetAlertMessage from '~/vue_merge_request_widget/components/mr_widget_alert_message.vue';
import { GlLink } from '@gitlab/ui';

describe('MrWidgetAlertMessage', () => {
  let wrapper;

  beforeEach(() => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(MrWidgetAlertMessage), {
      propsData: {},
      localVue,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when type is not provided', () => {
    it('should render a red message', () => {
      expect(wrapper.classes()).toContain('danger_message');
      expect(wrapper.classes()).not.toContain('warning_message');
    });
  });

  describe('when type === "danger"', () => {
    it('should render a red message', () => {
      wrapper.setProps({ type: 'danger' });

      expect(wrapper.classes()).toContain('danger_message');
      expect(wrapper.classes()).not.toContain('warning_message');
    });
  });

  describe('when type === "warning"', () => {
    it('should render a red message', () => {
      wrapper.setProps({ type: 'warning' });

      expect(wrapper.classes()).toContain('warning_message');
      expect(wrapper.classes()).not.toContain('danger_message');
    });
  });

  describe('when helpPath is not provided', () => {
    it('should not render a help icon/link', () => {
      const link = wrapper.find(GlLink);

      expect(link.exists()).toBe(false);
    });
  });

  describe('when helpPath is provided', () => {
    it('should render a help icon/link', () => {
      wrapper.setProps({ helpPath: '/path/to/help/docs' });
      const link = wrapper.find(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes().href).toBe('/path/to/help/docs');
    });
  });
});
