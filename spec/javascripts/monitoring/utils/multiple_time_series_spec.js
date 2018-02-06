import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { convertDatesMultipleSeries, singleRowMetricsMultipleSeries } from '../mock_data';

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
const timeSeries = createTimeSeries(convertedMetrics[0].queries, 428, 272, 120);
const firstTimeSeries = timeSeries[0];

describe('Multiple time series', () => {
  it('createTimeSeries returned array contains an object for each element', () => {
    expect(typeof firstTimeSeries.linePath).toEqual('string');
    expect(typeof firstTimeSeries.areaPath).toEqual('string');
    expect(typeof firstTimeSeries.timeSeriesScaleX).toEqual('function');
    expect(typeof firstTimeSeries.areaColor).toEqual('string');
    expect(typeof firstTimeSeries.lineColor).toEqual('string');
    expect(firstTimeSeries.values instanceof Array).toEqual(true);
  });

  it('createTimeSeries returns an array', () => {
    expect(timeSeries instanceof Array).toEqual(true);
    expect(timeSeries.length).toEqual(2);
  });
});
