import Vue from 'vue';
import MonitoringRow from '~/monitoring/components/monitoring_row.vue';
import { deploymentData, singleRowMetrics } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringRow);

  return new Component({
    propsData,
  }).$mount();
};

describe('MonitoringRow', () => {
  describe('Computed props', () => {
    it('bootstrapClass is set to col-md-6 when rowData is higher/equal to 2', () => {
      const component = createComponent({
        rowData: singleRowMetrics,
        updateAspectRatio: false,
        deploymentData,
      });

      expect(component.bootstrapClass).toEqual('col-md-6');
    });

    it('bootstrapClass is set to col-md-12 when rowData is lower than 2', () => {
      const component = createComponent({
        rowData: [singleRowMetrics[0]],
        updateAspectRatio: false,
        deploymentData,
      });

      expect(component.bootstrapClass).toEqual('col-md-12');
    });
  });

  it('has one column', () => {
    const component = createComponent({
      rowData: singleRowMetrics,
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelectorAll('.prometheus-svg-container').length)
        .toEqual(component.rowData.length);
  });

  it('has two columns', () => {
    const component = createComponent({
      rowData: singleRowMetrics,
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelectorAll('.col-md-6').length)
        .toEqual(component.rowData.length);
  });
});
