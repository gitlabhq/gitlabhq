import MonitoringStore from '~/monitoring/stores/monitoring_store';
import MonitoringMock, { deploymentData } from './mock_data';

describe('MonitoringStore', () => {
  this.store = new MonitoringStore();
  this.store.storeMetrics(MonitoringMock.data);

  it('contains one group that contains two queries sorted by priority', () => {
    expect(this.store.groups).toBeDefined();
    expect(this.store.groups.length).toEqual(1);
    expect(this.store.groups[0].metrics.length).toEqual(2);
  });

  it('gets the metrics count for every group', () => {
    expect(this.store.getMetricsCount()).toEqual(2);
  });

  it('contains deployment data', () => {
    this.store.storeDeploymentData(deploymentData);
    expect(this.store.deploymentData).toBeDefined();
    expect(this.store.deploymentData.length).toEqual(3);
    expect(typeof this.store.deploymentData[0]).toEqual('object');
  });
});
