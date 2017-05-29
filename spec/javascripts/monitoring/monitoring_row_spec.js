import Vue from 'vue';
import MonitoringRow from '~/monitoring/components/monitoring_row.vue';
import MonitoringStore from '~/monitoring/stores/monitoring_store';
import MonitoringMock from './mock_data';

describe('MonitoringRow component', () => {
  let component;
  let MonitoringRowComponent;

  beforeEach(() => {
    MonitoringRowComponent = Vue.extend(MonitoringRow);
    this.store = new MonitoringStore();
    this.store.storeMetrics(MonitoringMock);
  });

  afterEach(() => {
    MonitoringStore.singleton = null;
  });

  it('Sets the bootstrap class to col-md-6 when the rowData length is 2 or less', () => {
    component = new MonitoringRowComponent({
      propsData: {
        rowData: this.store.groups[0].metrics[0],
        updateAspectRatio: false,
      },
    }).$mount();

    expect(component.bootstrapClass()).toEqual('col-md-6');
  });

  it('has the rowData set to an array of a maximum length of 2', () => {
    component = new MonitoringRowComponent({
      propsData: {
        rowData: this.store.groups[0].metrics[0],
        updateAspectRatio: false,
      },
    }).$mount();

    expect(component.rowData.length).toEqual(2);
  });
});
