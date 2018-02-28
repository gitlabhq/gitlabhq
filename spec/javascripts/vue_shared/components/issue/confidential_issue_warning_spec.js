import Vue from 'vue';
import confidentialIssue from '~/vue_shared/components/issue/confidential_issue_warning.vue';

describe('Confidential Issue Warning Component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(confidentialIssue);
    vm = new Component().$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render confidential issue warning information', () => {
    expect(vm.$el.querySelector('i').className).toEqual('fa fa-eye-slash');
    expect(vm.$el.querySelector('span').textContent.trim()).toEqual('This is a confidential issue. Your comment will not be visible to the public.');
  });
});
