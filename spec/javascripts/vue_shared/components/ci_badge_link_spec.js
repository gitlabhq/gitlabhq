import Vue from 'vue';
import ciBadge from '~/vue_shared/components/ci_badge_link.vue';

describe('CI Badge Link Component', () => {
  let CIBadge;

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

  it('should render each status badge', () => {
    CIBadge = Vue.extend(ciBadge);
    Object.keys(statuses).map((status) => {
      const vm = new CIBadge({
        propsData: {
          status: statuses[status],
        },
      }).$mount();

      expect(vm.$el.getAttribute('href')).toEqual(statuses[status].details_path);
      expect(vm.$el.textContent.trim()).toEqual(statuses[status].text);
      expect(vm.$el.getAttribute('class')).toEqual(`ci-status ci-${statuses[status].group}`);
      expect(vm.$el.querySelector('svg')).toBeDefined();
      return vm;
    });
  });
});
