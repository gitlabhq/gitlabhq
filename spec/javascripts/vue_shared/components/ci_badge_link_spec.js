import Vue from 'vue';
import ciBadge from '~/vue_shared/components/ci_badge_link.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('CI Badge Link Component', () => {
  let CIBadge;
  let vm;

  const statuses = {
    canceled: {
      text: 'canceled',
      label: 'canceled',
      group: 'canceled',
      icon: 'icon_status_canceled',
      details_path: 'status/canceled',
    },
    created: {
      text: 'created',
      label: 'created',
      group: 'created',
      icon: 'icon_status_created',
      details_path: 'status/created',
    },
    failed: {
      text: 'failed',
      label: 'failed',
      group: 'failed',
      icon: 'icon_status_failed',
      details_path: 'status/failed',
    },
    manual: {
      text: 'manual',
      label: 'manual action',
      group: 'manual',
      icon: 'icon_status_manual',
      details_path: 'status/manual',
    },
    pending: {
      text: 'pending',
      label: 'pending',
      group: 'pending',
      icon: 'icon_status_pending',
      details_path: 'status/pending',
    },
    running: {
      text: 'running',
      label: 'running',
      group: 'running',
      icon: 'icon_status_running',
      details_path: 'status/running',
    },
    skipped: {
      text: 'skipped',
      label: 'skipped',
      group: 'skipped',
      icon: 'icon_status_skipped',
      details_path: 'status/skipped',
    },
    success_warining: {
      text: 'passed',
      label: 'passed',
      group: 'success_with_warnings',
      icon: 'icon_status_warning',
      details_path: 'status/warning',
    },
    success: {
      text: 'passed',
      label: 'passed',
      group: 'passed',
      icon: 'icon_status_success',
      details_path: 'status/passed',
    },
  };

  beforeEach(() => {
    CIBadge = Vue.extend(ciBadge);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render each status badge', () => {
    Object.keys(statuses).map((status) => {
      vm = mountComponent(CIBadge, { status: statuses[status] });
      expect(vm.$el.getAttribute('href')).toEqual(statuses[status].details_path);
      expect(vm.$el.textContent.trim()).toEqual(statuses[status].text);
      expect(vm.$el.getAttribute('class')).toEqual(`ci-status ci-${statuses[status].group}`);
      expect(vm.$el.querySelector('svg')).toBeDefined();
      return vm;
    });
  });

  it('should not render label', () => {
    vm = mountComponent(CIBadge, { status: statuses.canceled, showText: false });
    expect(vm.$el.textContent.trim()).toEqual('');
  });
});
