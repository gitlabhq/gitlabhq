import { groupQueriesByChartInfo } from '~/monitoring/stores/utils';

describe('groupQueriesByChartInfo', () => {
  let input;
  let output;

  it('groups metrics with the same chart title and y_axis label', () => {
    input = [
      { title: 'title', y_label: 'MB', queries: [{}] },
      { title: 'title', y_label: 'MB', queries: [{}] },
      { title: 'new title', y_label: 'MB', queries: [{}] },
    ];

    output = [
      { title: 'title', y_label: 'MB', queries: [{ metricId: null }, { metricId: null }] },
      { title: 'new title', y_label: 'MB', queries: [{ metricId: null }] },
    ];

    expect(groupQueriesByChartInfo(input)).toEqual(output);
  });

  // Functionality associated with the /additional_metrics endpoint
  it("associates a chart's stringified metric_id with the metric", () => {
    input = [{ id: 3, title: 'new title', y_label: 'MB', queries: [{}] }];
    output = [{ id: 3, title: 'new title', y_label: 'MB', queries: [{ metricId: '3' }] }];

    expect(groupQueriesByChartInfo(input)).toEqual(output);
  });

  // Functionality associated with the /metrics_dashboard endpoint
  it('aliases a stringified metrics_id on the metric to the metricId key', () => {
    input = [{ title: 'new title', y_label: 'MB', queries: [{ metric_id: 3 }] }];
    output = [{ title: 'new title', y_label: 'MB', queries: [{ metricId: '3', metric_id: 3 }] }];

    expect(groupQueriesByChartInfo(input)).toEqual(output);
  });
});
