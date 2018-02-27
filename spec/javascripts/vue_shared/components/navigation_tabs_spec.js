import Vue from 'vue';
import navigationTabs from '~/vue_shared/components/navigation_tabs.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('navigation tabs component', () => {
  let vm;
  let Component;
  let data;

  beforeEach(() => {
    data = [
      {
        name: 'All',
        scope: 'all',
        count: 1,
        isActive: true,
      },
      {
        name: 'Pending',
        scope: 'pending',
        count: 0,
        isActive: false,
      },
      {
        name: 'Running',
        scope: 'running',
        isActive: false,
      },
    ];

    Component = Vue.extend(navigationTabs);
    vm = mountComponent(Component, { tabs: data, scope: 'pipelines' });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render tabs', () => {
    expect(vm.$el.querySelectorAll('li').length).toEqual(data.length);
  });

  it('should render active tab', () => {
    expect(vm.$el.querySelector('.active .js-pipelines-tab-all')).toBeDefined();
  });

  it('should render badge', () => {
    expect(vm.$el.querySelector('.js-pipelines-tab-all .badge').textContent.trim()).toEqual('1');
    expect(vm.$el.querySelector('.js-pipelines-tab-pending .badge').textContent.trim()).toEqual('0');
  });

  it('should not render badge', () => {
    expect(vm.$el.querySelector('.js-pipelines-tab-running .badge')).toEqual(null);
  });

  it('should trigger onTabClick', () => {
    spyOn(vm, '$emit');
    vm.$el.querySelector('.js-pipelines-tab-pending').click();
    expect(vm.$emit).toHaveBeenCalledWith('onChangeTab', 'pending');
  });
});
