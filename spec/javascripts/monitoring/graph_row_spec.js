import Vue from 'vue';
import GraphRow from '~/monitoring/components/graph_row.vue';
import MonitoringMixins from '~/monitoring/mixins/monitoring_mixins';
import { deploymentData, convertDatesMultipleSeries, singleRowMetricsMultipleSeries } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphRow);

  return new Component({
    propsData,
  }).$mount();
};

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
describe('GraphRow', () => {
  beforeEach(() => {
    spyOn(MonitoringMixins.methods, 'formatDeployments').and.returnValue({});
  });
  describe('Computed props', () => {
    it('bootstrapClass is set to col-md-6 when rowData is higher/equal to 2', () => {
      const component = createComponent({
        rowData: convertedMetrics,
        updateAspectRatio: false,
        deploymentData,
      });

      expect(component.bootstrapClass).toEqual('col-md-6');
    });

    it('bootstrapClass is set to col-md-12 when rowData is lower than 2', () => {
      const component = createComponent({
        rowData: [convertedMetrics[0]],
        updateAspectRatio: false,
        deploymentData,
      });

      expect(component.bootstrapClass).toEqual('col-md-12');
    });
  });

  it('has one column', () => {
    const component = createComponent({
      rowData: convertedMetrics,
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelectorAll('.prometheus-svg-container').length)
        .toEqual(component.rowData.length);
  });

  it('has two columns', () => {
    const component = createComponent({
      rowData: convertedMetrics,
      updateAspectRatio: false,
      deploymentData,
    });

    expect(component.$el.querySelectorAll('.col-md-6').length)
        .toEqual(component.rowData.length);
  });
});
