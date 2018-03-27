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

  describe('Methods', () => {
    beforeEach(() => {
      vm = mountComponent(Legend, {
        legendTitle: 'legend',
        timeSeries,
        currentDataIndex: 0,
        unitOfDisplay: 'Req/Sec',
      });
    });

    it('formatMetricUsage should contain the unit of display and the current value selected via "currentDataIndex"', () => {
      const formattedMetricUsage = vm.formatMetricUsage(timeSeries[0]);
      const valueFromSeries = timeSeries[0].values[vm.currentDataIndex].value;

      expect(formattedMetricUsage.indexOf(vm.unitOfDisplay)).not.toEqual(-1);
      expect(formattedMetricUsage.indexOf(valueFromSeries)).not.toEqual(-1);
    });

    it('strokeDashArray', () => {
      const dashedArray = vm.strokeDashArray('dashed');
      const dottedArray = vm.strokeDashArray('dotted');

      expect(dashedArray).toEqual('6, 3');
      expect(dottedArray).toEqual('3, 3');
    });

    it('summaryMetrics gets the average and max of a series', () => {
      const summary = vm.summaryMetrics(timeSeries[0]);

      expect(summary.indexOf('Max')).not.toEqual(-1);
      expect(summary.indexOf('Avg')).not.toEqual(-1);
    });
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
