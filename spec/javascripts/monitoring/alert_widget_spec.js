import Vue from 'vue';
import AlertWidget from 'ee/monitoring/components/alert_widget.vue';
import AlertsService from 'ee/monitoring/services/alerts_service';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('AlertWidget', () => {
  let AlertWidgetComponent;
  let vm;
  const props = {
    alertsEndpoint: '',
    customMetricId: 5,
    label: 'alert-label',
    currentAlerts: ['my/alert.json'],
  };

  beforeAll(() => {
    AlertWidgetComponent = Vue.extend(AlertWidget);
  });

  beforeEach(() => {
    setFixtures('<div id="alert-widget"></div>');
  });

  afterEach(() => {
    if (vm) vm.$destroy();
  });

  it('displays a loading spinner when fetching alerts', done => {
    let resolveReadAlert;

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(
      new Promise(cb => {
        resolveReadAlert = cb;
      }),
    );
    vm = mountComponent(AlertWidgetComponent, props, '#alert-widget');

    // expect loading spinner to exist during fetch
    expect(vm.isLoading).toBeTruthy();
    expect(vm.$el.querySelector('.loading-container')).toBeVisible();

    resolveReadAlert({ operator: '=', threshold: 42 });

    // expect loading spinner to go away after fetch
    setTimeout(() =>
      vm.$nextTick(() => {
        expect(vm.isLoading).toEqual(false);
        expect(vm.$el.querySelector('.loading-container')).toBeHidden();
        done();
      }),
    );
  });

  it('displays an error message when fetch fails', done => {
    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.reject());
    vm = mountComponent(AlertWidgetComponent, props, '#alert-widget');

    setTimeout(() =>
      vm.$nextTick(() => {
        expect(vm.errorMessage).toBe('Error fetching alert');
        expect(vm.isLoading).toEqual(false);
        expect(vm.$el.querySelector('.alert-error-message')).toBeVisible();
        done();
      }),
    );
  });

  it('displays an alert summary when fetch succeeds', done => {
    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(
      Promise.resolve({ operator: '>', threshold: 42 }),
    );
    vm = mountComponent(AlertWidgetComponent, props, '#alert-widget');

    setTimeout(() =>
      vm.$nextTick(() => {
        expect(vm.isLoading).toEqual(false);
        expect(vm.alertSummary).toBe('alert-label > 42');
        expect(vm.$el.querySelector('.alert-current-setting')).toBeVisible();
        done();
      }),
    );
  });

  it('opens and closes a dropdown menu by clicking close button', done => {
    vm = mountComponent(AlertWidgetComponent, { ...props, currentAlerts: [] });

    expect(vm.isOpen).toEqual(false);
    expect(vm.$el.querySelector('.alert-dropdown-menu')).toBeHidden();

    vm.$el.querySelector('.alert-dropdown-button').click();

    Vue.nextTick(() => {
      expect(vm.isOpen).toEqual(true);
      expect(vm.$el).toHaveClass('show');

      vm.$el.querySelector('.dropdown-menu-close').click();

      Vue.nextTick(() => {
        expect(vm.isOpen).toEqual(false);
        expect(vm.$el).not.toHaveClass('show');
        done();
      });
    });
  });

  it('opens and closes a dropdown menu by clicking outside the menu', done => {
    vm = mountComponent(AlertWidgetComponent, { ...props, currentAlerts: [] });

    expect(vm.isOpen).toEqual(false);
    expect(vm.$el.querySelector('.alert-dropdown-menu')).toBeHidden();

    vm.$el.querySelector('.alert-dropdown-button').click();

    Vue.nextTick(() => {
      expect(vm.isOpen).toEqual(true);
      expect(vm.$el).toHaveClass('show');

      document.body.click();

      Vue.nextTick(() => {
        expect(vm.isOpen).toEqual(false);
        expect(vm.$el).not.toHaveClass('show');
        done();
      });
    });
  });

  it('creates an alert with an appropriate handler', done => {
    const alertParams = {
      operator: '<',
      threshold: 4,
      prometheus_metric_id: 5,
    };

    spyOn(AlertsService.prototype, 'createAlert').and.returnValue(
      Promise.resolve({
        alert_path: 'foo/bar',
        ...alertParams,
      }),
    );

    vm = mountComponent(AlertWidgetComponent, { ...props, currentAlerts: [] });
    vm.$refs.widgetForm.$emit('create', alertParams);

    expect(AlertsService.prototype.createAlert).toHaveBeenCalledWith(alertParams);
    Vue.nextTick(() => {
      expect(vm.isLoading).toEqual(false);
      expect(vm.alertSummary).toBe('alert-label < 4');
      done();
    });
  });

  it('updates an alert with an appropriate handler', done => {
    const alertPath = 'my/test/alert.json';
    const alertParams = {
      operator: '<',
      threshold: 4,
    };

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.resolve(alertParams));
    spyOn(AlertsService.prototype, 'updateAlert').and.returnValue(Promise.resolve());

    vm = mountComponent(AlertWidgetComponent, { ...props, currentAlerts: [alertPath] });
    vm.$refs.widgetForm.$emit('update', {
      ...alertParams,
      alert: alertPath,
      operator: '=',
      threshold: 12,
    });

    expect(AlertsService.prototype.updateAlert).toHaveBeenCalledWith(alertPath, {
      ...alertParams,
      operator: '=',
      threshold: 12,
    });
    Vue.nextTick(() => {
      expect(vm.isLoading).toEqual(false);
      expect(vm.alertSummary).toBe('alert-label = 12');
      done();
    });
  });

  it('deletes an alert with an appropriate handler', done => {
    const alertPath = 'my/test/alert.json';
    const alertParams = {
      operator: '<',
      threshold: 4,
    };

    spyOn(AlertsService.prototype, 'readAlert').and.returnValue(Promise.resolve(alertParams));
    spyOn(AlertsService.prototype, 'deleteAlert').and.returnValue(Promise.resolve());

    vm = mountComponent(AlertWidgetComponent, { ...props, currentAlerts: [alertPath] });
    vm.$refs.widgetForm.$emit('delete', { alert: alertPath });

    expect(AlertsService.prototype.deleteAlert).toHaveBeenCalledWith(alertPath);
    Vue.nextTick(() => {
      expect(vm.isLoading).toEqual(false);
      expect(vm.alertSummary).toBeFalsy();
      done();
    });
  });
});
