import Vue from 'vue';
import _ from 'underscore';
import Cookies from 'js-cookie';
import epicSidebar from 'ee/epics/sidebar/components/sidebar_app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { props } from '../../epic_show/mock_data';

describe('epicSidebar', () => {
  let vm;
  let originalCookieState;
  let EpicSidebar;
  const {
    updateEndpoint,
    labelsPath,
    labelsWebUrl,
    epicsWebUrl,
    labels,
  } = props;

  beforeEach(() => {
    setFixtures(`
      <div class="page-with-contextual-sidebar right-sidebar-expanded">
        <div id="epic-sidebar"></div>
      </div>
    `);

    originalCookieState = Cookies.get('collapsed_gutter');
    Cookies.set('collapsed_gutter', null);
    EpicSidebar = Vue.extend(epicSidebar);
    vm = mountComponent(EpicSidebar, {
      endpoint: gl.TEST_HOST,
      initialLabels: labels,
      updatePath: updateEndpoint,
      labelsPath,
      labelsWebUrl,
      epicsWebUrl,
    }, '#epic-sidebar');
  });

  afterEach(() => {
    Cookies.set('collapsed_gutter', originalCookieState);
  });

  it('should render right-sidebar-expanded class when not collapsed', () => {
    expect(vm.$el.classList.contains('right-sidebar-expanded')).toEqual(true);
  });

  it('should render min date sidebar-date-picker', () => {
    vm = mountComponent(EpicSidebar, {
      endpoint: gl.TEST_HOST,
      initialStartDate: '2017-01-01',
      initialLabels: labels,
      updatePath: updateEndpoint,
      labelsPath,
      labelsWebUrl,
      epicsWebUrl,
    });

    expect(vm.$el.querySelector('.value-content strong').innerText.trim()).toEqual('Jan 1, 2017');
  });

  it('should render max date sidebar-date-picker', () => {
    vm = mountComponent(EpicSidebar, {
      endpoint: gl.TEST_HOST,
      initialEndDate: '2018-01-01',
      initialLabels: labels,
      updatePath: updateEndpoint,
      labelsPath,
      labelsWebUrl,
      epicsWebUrl,
    });

    expect(vm.$el.querySelector('.value-content strong').innerText.trim()).toEqual('Jan 1, 2018');
  });

  it('should render both sidebar-date-picker', () => {
    vm = mountComponent(EpicSidebar, {
      endpoint: gl.TEST_HOST,
      initialStartDate: '2017-01-01',
      initialEndDate: '2018-01-01',
      initialLabels: labels,
      updatePath: updateEndpoint,
      labelsPath,
      labelsWebUrl,
      epicsWebUrl,
    });

    const datePickers = vm.$el.querySelectorAll('.block');
    expect(datePickers[0].querySelector('.value-content strong').innerText.trim()).toEqual('Jan 1, 2017');
    expect(datePickers[1].querySelector('.value-content strong').innerText.trim()).toEqual('Jan 1, 2018');
  });

  describe('when collapsed', () => {
    beforeEach(() => {
      Cookies.set('collapsed_gutter', 'true');
      vm = mountComponent(EpicSidebar, {
        endpoint: gl.TEST_HOST,
        initialStartDate: '2017-01-01',
        initialLabels: labels,
        updatePath: updateEndpoint,
        labelsPath,
        labelsWebUrl,
        epicsWebUrl,
      });
    });

    it('should render right-sidebar-collapsed class', () => {
      expect(vm.$el.classList.contains('right-sidebar-collapsed')).toEqual(true);
    });

    it('should render collapsed grouped date picker', () => {
      expect(vm.$el.querySelector('.sidebar-collapsed-icon span').innerText.trim()).toEqual('From Jan 1 2017');
    });
  });

  describe('toggleSidebar', () => {
    it('should toggle collapsed_gutter cookie', () => {
      expect(vm.$el.classList.contains('right-sidebar-expanded')).toEqual(true);
      vm.$el.querySelector('.gutter-toggle').click();

      expect(Cookies.get('collapsed_gutter')).toEqual('true');
    });

    it('should toggle contentContainer css class', () => {
      const contentContainer = document.querySelector('.page-with-contextual-sidebar');
      expect(contentContainer.classList.contains('right-sidebar-expanded')).toEqual(true);
      expect(contentContainer.classList.contains('right-sidebar-collapsed')).toEqual(false);

      vm.$el.querySelector('.gutter-toggle').click();
      expect(contentContainer.classList.contains('right-sidebar-expanded')).toEqual(false);
      expect(contentContainer.classList.contains('right-sidebar-collapsed')).toEqual(true);
    });
  });

  describe('saveDate', () => {
    let interceptor;
    let component;

    beforeEach(() => {
      interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify({}), {
          status: 200,
        }));
      };
      Vue.http.interceptors.push(interceptor);
      component = new EpicSidebar({
        propsData: {
          endpoint: gl.TEST_HOST,
          initialLabels: labels,
          updatePath: updateEndpoint,
          labelsPath,
          labelsWebUrl,
          epicsWebUrl,
        },
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should save startDate', (done) => {
      const date = '2017-01-01';
      expect(component.store.startDate).toBeUndefined();
      component.saveStartDate(date)
        .then(() => {
          expect(component.store.startDate).toEqual(date);
          done();
        })
        .catch(done.fail);
    });

    it('should save endDate', (done) => {
      const date = '2017-01-01';
      expect(component.store.endDate).toBeUndefined();
      component.saveEndDate(date)
        .then(() => {
          expect(component.store.endDate).toEqual(date);
          done();
        })
        .catch(done.fail);
    });

    it('should handle errors gracefully', () => {});
  });

  describe('handleLabelClick', () => {
    const label = {
      id: 1,
      title: 'Foo',
      color: ['#BADA55'],
      text_color: '#FFFFFF',
    };

    it('initializes `epicContext.labels` as empty array when `label.isAny` is `true`', () => {
      const labelIsAny = { isAny: true };
      vm.handleLabelClick(labelIsAny);
      expect(Array.isArray(vm.epicContext.labels)).toBe(true);
      expect(vm.epicContext.labels.length).toBe(0);
    });

    it('adds provided `label` to epicContext.labels', () => {
      vm.handleLabelClick(label);
      // epicContext.labels gets initialized with initialLabels, hence
      // newly insert label will be at second position (index `1`)
      expect(vm.epicContext.labels.length).toBe(2);
      expect(vm.epicContext.labels[1].id).toBe(label.id);
      vm.handleLabelClick(label);
    });

    it('filters epicContext.labels to exclude provided `label` if it is already present in `epicContext.labels`', () => {
      vm.handleLabelClick(label); // Select
      vm.handleLabelClick(label); // Un-select
      expect(vm.epicContext.labels.length).toBe(1);
      expect(vm.epicContext.labels[0].id).toBe(labels[0].id);
    });
  });

  describe('saveDate error', () => {
    let interceptor;
    let component;

    beforeEach(() => {
      interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify({}), {
          status: 500,
        }));
      };
      Vue.http.interceptors.push(interceptor);
      component = new EpicSidebar({
        propsData: {
          endpoint: gl.TEST_HOST,
          initialLabels: labels,
          updatePath: updateEndpoint,
          labelsPath,
          labelsWebUrl,
          epicsWebUrl,
        },
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
    });

    it('should handle errors gracefully', (done) => {
      const date = '2017-01-01';
      expect(component.store.startDate).toBeUndefined();
      component.saveDate('start', date)
        .then(() => {
          expect(component.store.startDate).toBeUndefined();
          done();
        })
        .catch(done.fail);
    });
  });
});
