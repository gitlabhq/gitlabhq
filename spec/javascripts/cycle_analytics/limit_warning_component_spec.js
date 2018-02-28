import Vue from 'vue';
import Translate from '~/vue_shared/translate';
import limitWarningComp from '~/cycle_analytics/components/limit_warning_component.vue';

Vue.use(Translate);

describe('Limit warning component', () => {
  let component;
  let LimitWarningComponent;

  beforeEach(() => {
    LimitWarningComponent = Vue.extend(limitWarningComp);
  });

  it('should not render if count is not exactly than 50', () => {
    component = new LimitWarningComponent({
      propsData: {
        count: 5,
      },
    }).$mount();

    expect(component.$el.textContent.trim()).toBe('');

    component = new LimitWarningComponent({
      propsData: {
        count: 55,
      },
    }).$mount();

    expect(component.$el.textContent.trim()).toBe('');
  });

  it('should render if count is exactly 50', () => {
    component = new LimitWarningComponent({
      propsData: {
        count: 50,
      },
    }).$mount();

    expect(component.$el.textContent.trim()).toBe('Showing 50 events');
  });
});
