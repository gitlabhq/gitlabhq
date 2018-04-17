import Vue from 'vue';
import GraphLegend from '~/monitoring/components/graph/legend.vue';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from '../mock_data';

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);

const defaultValuesComponent = {};

const timeSeries = createTimeSeries(convertedMetrics[0].queries, 500, 300, 120);

defaultValuesComponent.timeSeries = timeSeries;

describe('Legend Component', () => {
  let vm;
  let Legend;

  beforeEach(() => {
    Legend = Vue.extend(GraphLegend);
  });

  describe('View', () => {
    beforeEach(() => {
      vm = mountComponent(Legend, {
        legendTitle: 'legend',
        timeSeries,
        currentDataIndex: 0,
        unitOfDisplay: 'Req/Sec',
      });
    });

    it('should render the usage, title and time with multiple time series', () => {
      const titles = vm.$el.querySelectorAll('.legend-metric-title');

      expect(titles[0].textContent.indexOf('1xx')).not.toEqual(-1);
      expect(titles[1].textContent.indexOf('2xx')).not.toEqual(-1);
    });

    it('should container the same number of rows in the table as time series', () => {
      expect(vm.$el.querySelectorAll('.prometheus-table tr').length).toEqual(vm.timeSeries.length);
    });
  });
});
