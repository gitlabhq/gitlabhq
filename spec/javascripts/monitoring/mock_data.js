import {
  anomalyMockGraphData as importedAnomalyMockGraphData,
  metricsGroupsAPIResponse as importedMetricsGroupsAPIResponse,
  environmentData as importedEnvironmentData,
  dashboardGitResponse as importedDashboardGitResponse,
} from '../../frontend/monitoring/mock_data';

export const anomalyMockGraphData = importedAnomalyMockGraphData;
export const metricsGroupsAPIResponse = importedMetricsGroupsAPIResponse;
export const environmentData = importedEnvironmentData;
export const dashboardGitResponse = importedDashboardGitResponse;

export const mockApiEndpoint = `${gl.TEST_HOST}/monitoring/mock`;

export const mockedQueryResultPayload = {
  metricId: '17_system_metrics_kubernetes_container_memory_average',
  result: [
    {
      metric: {},
      values: [
        [1563272065.589, '10.396484375'],
        [1563272125.589, '10.333984375'],
        [1563272185.589, '10.333984375'],
        [1563272245.589, '10.333984375'],
        [1563272305.589, '10.333984375'],
        [1563272365.589, '10.333984375'],
        [1563272425.589, '10.38671875'],
        [1563272485.589, '10.333984375'],
        [1563272545.589, '10.333984375'],
        [1563272605.589, '10.333984375'],
        [1563272665.589, '10.333984375'],
        [1563272725.589, '10.333984375'],
        [1563272785.589, '10.396484375'],
        [1563272845.589, '10.333984375'],
        [1563272905.589, '10.333984375'],
        [1563272965.589, '10.3984375'],
        [1563273025.589, '10.337890625'],
        [1563273085.589, '10.34765625'],
        [1563273145.589, '10.337890625'],
        [1563273205.589, '10.337890625'],
        [1563273265.589, '10.337890625'],
        [1563273325.589, '10.337890625'],
        [1563273385.589, '10.337890625'],
        [1563273445.589, '10.337890625'],
        [1563273505.589, '10.337890625'],
        [1563273565.589, '10.337890625'],
        [1563273625.589, '10.337890625'],
        [1563273685.589, '10.337890625'],
        [1563273745.589, '10.337890625'],
        [1563273805.589, '10.337890625'],
        [1563273865.589, '10.390625'],
        [1563273925.589, '10.390625'],
      ],
    },
  ],
};

export const mockedQueryResultPayloadCoresTotal = {
  metricId: '13_system_metrics_kubernetes_container_cores_total',
  result: [
    {
      metric: {},
      values: [
        [1563272065.589, '9.396484375'],
        [1563272125.589, '9.333984375'],
        [1563272185.589, '9.333984375'],
        [1563272245.589, '9.333984375'],
        [1563272305.589, '9.333984375'],
        [1563272365.589, '9.333984375'],
        [1563272425.589, '9.38671875'],
        [1563272485.589, '9.333984375'],
        [1563272545.589, '9.333984375'],
        [1563272605.589, '9.333984375'],
        [1563272665.589, '9.333984375'],
        [1563272725.589, '9.333984375'],
        [1563272785.589, '9.396484375'],
        [1563272845.589, '9.333984375'],
        [1563272905.589, '9.333984375'],
        [1563272965.589, '9.3984375'],
        [1563273025.589, '9.337890625'],
        [1563273085.589, '9.34765625'],
        [1563273145.589, '9.337890625'],
        [1563273205.589, '9.337890625'],
        [1563273265.589, '9.337890625'],
        [1563273325.589, '9.337890625'],
        [1563273385.589, '9.337890625'],
        [1563273445.589, '9.337890625'],
        [1563273505.589, '9.337890625'],
        [1563273565.589, '9.337890625'],
        [1563273625.589, '9.337890625'],
        [1563273685.589, '9.337890625'],
        [1563273745.589, '9.337890625'],
        [1563273805.589, '9.337890625'],
        [1563273865.589, '9.390625'],
        [1563273925.589, '9.390625'],
      ],
    },
  ],
};

export const graphDataPrometheusQuery = {
  title: 'Super Chart A2',
  type: 'single-stat',
  weight: 2,
  metrics: [
    {
      id: 'metric_a1',
      metricId: '2',
      query: 'max(go_memstats_alloc_bytes{job="prometheus"}) by (job) /1024/1024',
      unit: 'MB',
      label: 'Total Consumption',
      metric_id: 2,
      prometheus_endpoint_path:
        '/root/kubernetes-gke-project/environments/35/prometheus/api/v1/query?query=max%28go_memstats_alloc_bytes%7Bjob%3D%22prometheus%22%7D%29+by+%28job%29+%2F1024%2F1024',
      result: [
        {
          metric: { job: 'prometheus' },
          value: ['2019-06-26T21:03:20.881Z', 91],
        },
      ],
    },
  ],
};

export const graphDataPrometheusQueryRange = {
  title: 'Super Chart A1',
  type: 'area-chart',
  weight: 2,
  metrics: [
    {
      id: 'metric_a1',
      metricId: '2',
      query_range:
        'avg(sum(container_memory_usage_bytes{container_name!="POD",pod_name=~"^%{ci_environment_slug}-(.*)",namespace="%{kube_namespace}"}) by (job)) without (job)  /1024/1024/1024',
      unit: 'MB',
      label: 'Total Consumption',
      metric_id: 2,
      prometheus_endpoint_path:
        '/root/kubernetes-gke-project/environments/35/prometheus/api/v1/query?query=max%28go_memstats_alloc_bytes%7Bjob%3D%22prometheus%22%7D%29+by+%28job%29+%2F1024%2F1024',
      result: [
        {
          metric: {},
          values: [[1495700554.925, '8.0390625'], [1495700614.925, '8.0390625']],
        },
      ],
    },
  ],
};

export const graphDataPrometheusQueryRangeMultiTrack = {
  title: 'Super Chart A3',
  type: 'heatmap',
  weight: 3,
  x_label: 'Status Code',
  y_label: 'Time',
  metrics: [
    {
      metricId: '1',
      id: 'response_metrics_nginx_ingress_throughput_status_code',
      query_range:
        'sum(rate(nginx_upstream_responses_total{upstream=~"%{kube_namespace}-%{ci_environment_slug}-.*"}[60m])) by (status_code)',
      unit: 'req / sec',
      label: 'Status Code',
      metric_id: 1,
      prometheus_endpoint_path:
        '/root/rails_nodb/environments/3/prometheus/api/v1/query_range?query=sum%28rate%28nginx_upstream_responses_total%7Bupstream%3D~%22%25%7Bkube_namespace%7D-%25%7Bci_environment_slug%7D-.%2A%22%7D%5B2m%5D%29%29+by+%28status_code%29',
      result: [
        {
          metric: { status_code: '1xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 0],
            ['2019-08-30T16:00:00.000Z', 2],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 0],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 3],
          ],
        },
        {
          metric: { status_code: '2xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 1],
            ['2019-08-30T16:00:00.000Z', 3],
            ['2019-08-30T17:00:00.000Z', 6],
            ['2019-08-30T18:00:00.000Z', 10],
            ['2019-08-30T19:00:00.000Z', 8],
            ['2019-08-30T20:00:00.000Z', 6],
          ],
        },
        {
          metric: { status_code: '3xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 1],
            ['2019-08-30T16:00:00.000Z', 2],
            ['2019-08-30T17:00:00.000Z', 3],
            ['2019-08-30T18:00:00.000Z', 3],
            ['2019-08-30T19:00:00.000Z', 2],
            ['2019-08-30T20:00:00.000Z', 1],
          ],
        },
        {
          metric: { status_code: '4xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 2],
            ['2019-08-30T16:00:00.000Z', 0],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 2],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 2],
          ],
        },
        {
          metric: { status_code: '5xx' },
          values: [
            ['2019-08-30T15:00:00.000Z', 0],
            ['2019-08-30T16:00:00.000Z', 1],
            ['2019-08-30T17:00:00.000Z', 0],
            ['2019-08-30T18:00:00.000Z', 0],
            ['2019-08-30T19:00:00.000Z', 0],
            ['2019-08-30T20:00:00.000Z', 2],
          ],
        },
      ],
    },
  ],
};
