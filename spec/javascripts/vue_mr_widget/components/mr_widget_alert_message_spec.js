import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import MrWidgetAlertMessage from '~/vue_merge_request_widget/components/mr_widget_alert_message.vue';

describe('MrWidgetAlertMessage', () => {
  let wrapper;

  beforeEach(() => {
    const localVue = createLocalVue();

    wrapper = shallowMount(localVue.extend(MrWidgetAlertMessage), {
      propsData: {},
      localVue,
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when type is not provided', () => {
    it('should render a red message', done => {
      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes()).toContain('danger_message');
        expect(wrapper.classes()).not.toContain('warning_message');
        done();
      });
    });
  });

  describe('when type === "danger"', () => {
    it('should render a red message', done => {
      wrapper.setProps({ type: 'danger' });
      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes()).toContain('danger_message');
        expect(wrapper.classes()).not.toContain('warning_message');
        done();
      });
    });
  });

  describe('when type === "warning"', () => {
    it('should render a red message', done => {
      wrapper.setProps({ type: 'warning' });
      wrapper.vm.$nextTick(() => {
        expect(wrapper.classes()).toContain('warning_message');
        expect(wrapper.classes()).not.toContain('danger_message');
        done();
      });
    });
  });

  describe('when helpPath is not provided', () => {
    it('should not render a help icon/link', done => {
      wrapper.vm.$nextTick(() => {
        const link = wrapper.find(GlLink);

        expect(link.exists()).toBe(false);
        done();
      });
    });
  });

  describe('when helpPath is provided', () => {
    it('should render a help icon/link', done => {
      wrapper.setProps({ helpPath: '/path/to/help/docs' });
      wrapper.vm.$nextTick(() => {
        const link = wrapper.find(GlLink);

        expect(link.exists()).toBe(true);
        expect(link.attributes().href).toBe('/path/to/help/docs');
        done();
      });
    });
  });
});
