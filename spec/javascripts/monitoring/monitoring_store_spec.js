import MonitoringStore from '~/monitoring/stores/monitoring_store';
import MonitoringMock from './mock_data';

describe('MonitoringStore', () => {
  beforeEach(() => {
    this.store = new MonitoringStore();
    this.store.storeMetrics(MonitoringMock);
  });

  afterEach(() => {
    MonitoringStore.singleton = null;
  });

  it('stores one group that contains two queries sorted by priority in one row', () => {
    expect(this.store.groups).toBeDefined();
    expect(this.store.groups.length).toEqual(1);
    expect(this.store.groups[0].metrics.length).toEqual(1);
  });

  it('gets the metrics count for every group', () => {
    expect(this.store.getMetricsCount()).toEqual(1);
  });
});
