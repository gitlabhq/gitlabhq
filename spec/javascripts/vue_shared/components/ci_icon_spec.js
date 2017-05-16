import Vue from 'vue';
import ciIcon from '~/vue_shared/components/ci_icon.vue';

describe('CI Icon component', () => {
  let CiIcon;
  beforeEach(() => {
    CiIcon = Vue.extend(ciIcon);
  });

  it('should render a span element with an svg', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_success',
        },
      },
    }).$mount();

    expect(component.$el.tagName).toEqual('SPAN');
    expect(component.$el.querySelector('span > svg')).toBeDefined();
  });

  it('should render a success status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_success',
          group: 'success',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-success')).toEqual(true);
  });

  it('should render a failed status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_failed',
          group: 'failed',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-failed')).toEqual(true);
  });

  it('should render success with warnings status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_warning',
          group: 'warning',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-warning')).toEqual(true);
  });

  it('should render pending status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_pending',
          group: 'pending',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-pending')).toEqual(true);
  });

  it('should render running status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_running',
          group: 'running',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-running')).toEqual(true);
  });

  it('should render created status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_created',
          group: 'created',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-created')).toEqual(true);
  });

  it('should render skipped status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_skipped',
          group: 'skipped',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-skipped')).toEqual(true);
  });

  it('should render canceled status', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_canceled',
          group: 'canceled',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-canceled')).toEqual(true);
  });

  it('should render status for manual action', () => {
    const component = new CiIcon({
      propsData: {
        status: {
          icon: 'icon_status_manual',
          group: 'manual',
        },
      },
    }).$mount();

    expect(component.$el.classList.contains('ci-status-icon-manual')).toEqual(true);
  });
});
