import createTimeSeries from '~/monitoring/utils/multiple_time_series';
import { convertDatesMultipleSeries, singleRowMetricsMultipleSeries } from '../mock_data';

const convertedMetrics = convertDatesMultipleSeries(singleRowMetricsMultipleSeries);
const timeSeries = createTimeSeries(convertedMetrics[0].queries[0].result, 428, 272, 120);

describe('Multiple time series', () => {
  it('createTimeSeries returned array contains an object for each element', () => {
    expect(typeof timeSeries[0].linePath).toEqual('string');
    expect(typeof timeSeries[0].areaPath).toEqual('string');
    expect(typeof timeSeries[0].timeSeriesScaleX).toEqual('function');
    expect(typeof timeSeries[0].timeSeriesScaleY).toEqual('function');
    expect(timeSeries[0].values instanceof Array).toEqual(true);
  });

  it('createTimeSeries returns an array', () => {
    expect(timeSeries instanceof Array).toEqual(true);
    expect(timeSeries.length).toEqual(5);
  });
});
