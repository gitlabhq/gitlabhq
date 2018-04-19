import Vue from 'vue';
import ciIcon from '~/vue_shared/components/ci_icon.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('CI Icon component', () => {
  const Component = Vue.extend(ciIcon);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  it('should render a span element with an svg', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_success',
      },
    });

    expect(vm.$el.tagName).toEqual('SPAN');
    expect(vm.$el.querySelector('span > svg')).toBeDefined();
  });

  it('should render a success status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_success',
        group: 'success',
      },
    })();

    expect(vm.$el.classList.contains('ci-status-icon-success')).toEqual(true);
  });

  it('should render a failed status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_failed',
        group: 'failed',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-failed')).toEqual(true);
  });

  it('should render success with warnings status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_warning',
        group: 'warning',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-warning')).toEqual(true);
  });

  it('should render pending status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_pending',
        group: 'pending',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-pending')).toEqual(true);
  });

  it('should render running status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_running',
        group: 'running',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-running')).toEqual(true);
  });

  it('should render created status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_created',
        group: 'created',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-created')).toEqual(true);
  });

  it('should render skipped status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_skipped',
        group: 'skipped',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-skipped')).toEqual(true);
  });

  it('should render canceled status', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_canceled',
        group: 'canceled',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-canceled')).toEqual(true);
  });

  it('should render status for manual action', () => {
    vm = mountComponent(Component, {
      status: {
        icon: 'icon_status_manual',
        group: 'manual',
      },
    });

    expect(vm.$el.classList.contains('ci-status-icon-manual')).toEqual(true);
  });
});
