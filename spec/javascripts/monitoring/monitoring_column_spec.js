import Vue from 'vue';
import MonitoringColumn from '~/monitoring/components/monitoring_column.vue';
import MonitoringStore from '~/monitoring/stores/monitoring_store';
import MonitoringMock from './mock_data';

describe('MonitoringColumn Component', () => {
  let component;
  let MonitoringColumnComponent;
  const store = new MonitoringStore();
  store.storeMetrics(MonitoringMock);
  this.column = (store.groups[0].metrics[0])[0];

  beforeEach(() => {
    MonitoringColumnComponent = Vue.extend(MonitoringColumn);
  });

  afterAll(() => {
    MonitoringStore.singleton = null;
  });

  it('has a title', () => {
    component = new MonitoringColumnComponent({
      propsData: {
        updateAspectRatio: false,
        classType: 'col-md-12',
        columnData: this.column,
      },
    }).$mount();

    expect(component.$el.querySelector('.text-center').innerText).toBe(this.column.title);
  });

  it('has a axis container with labels', () => {
    component = new MonitoringColumnComponent({
      propsData: {
        updateAspectRatio: false,
        classType: 'col-md-12',
        columnData: this.column,
      },
    }).$mount();

    const axisLabelContainer = component.$el.querySelector('.axis-label-container');
    expect(axisLabelContainer.querySelectorAll('line').length).toEqual(2);
    expect(axisLabelContainer.querySelectorAll('rect').length).toEqual(3);
    expect(axisLabelContainer.querySelectorAll('text').length).toEqual(4);
  });

  it('has a graph overlay to allow mouseover events', () => {
    component = new MonitoringColumnComponent({
      propsData: {
        updateAspectRatio: false,
        classType: 'col-md-12',
        columnData: this.column,
      },
    }).$mount();

    expect(component.$el.querySelector('.prometheus-graph-overlay')).toBeDefined();
  });

  it('contains a path, axis and lines to represent the data', () => {
    component = new MonitoringColumnComponent({
      propsData: {
        updateAspectRatio: false,
        classType: 'col-md-12',
        columnData: this.column,
      },
    }).$mount();

    expect(component.svgContainer.querySelector('.x-axis')).toBeDefined();
    expect(component.svgContainer.querySelector('.y-axis')).toBeDefined();
    expect(component.svgContainer.querySelector('.metric-area')).toBeDefined();
    expect(component.svgContainer.querySelector('.metric-line')).toBeDefined();
    const viewBoxMeasurements = component.svgContainer.getAttribute('viewBox').split(' ');
    // expect(parseInt(viewBoxMeasurements[2], 10)).toBeGreaterThan(0);
    expect(parseInt(viewBoxMeasurements[3], 10)).toBeGreaterThan(0);
  });

  it('redraws the graph when the screen is resized', (done) => {
    component = new MonitoringColumnComponent({
      propsData: {
        updateAspectRatio: false,
        classType: 'col-md-12',
        columnData: this.column,
      },
    }).$mount();
    spyOn(component, 'redraw');

    component.updateAspectRatio = true;
    Vue.nextTick(() => {
      expect(component.redraw).toHaveBeenCalled();
      done();
    });
  });
});
