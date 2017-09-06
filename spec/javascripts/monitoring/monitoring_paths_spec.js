import Vue from 'vue';
import MonitoringPaths from '~/monitoring/components/monitoring_paths.vue';
import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { singleRowMetricsMultipleSeries, convertDatesMultipleSeries } from './mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(MonitoringPaths);

  return new Component({
    propsData,
  }).$mount();
};

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);

const timeSeries = createTimeSeries(convertedMetrics[0].queries[0].result, 428, 272, 120);

describe('Monitoring Paths', () => {
  it('renders two paths to represent a line and the area underneath it', () => {
    const component = createComponent({
      generatedLinePath: timeSeries[0].linePath,
      generatedAreaPath: timeSeries[0].areaPath,
      lineColor: '#ccc',
      areaColor: '#fff',
    });
    const metricArea = component.$el.querySelector('.metric-area');
    const metricLine = component.$el.querySelector('.metric-line');

    expect(metricArea.getAttribute('fill')).toBe('#fff');
    expect(metricArea.getAttribute('d')).toBe(timeSeries[0].areaPath);
    expect(metricLine.getAttribute('stroke')).toBe('#ccc');
    expect(metricLine.getAttribute('d')).toBe(timeSeries[0].linePath);
  });
});
