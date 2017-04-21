import d3 from 'd3';
import PrometheusGraph from '~/monitoring/prometheus_graph';
import Deployments from '~/monitoring/deployments';
import { prometheusMockData } from './prometheus_mock_data';

describe('Metrics deployments', () => {
  const fixtureName = 'static/environments/metrics.html.raw';
  let deployment;
  let prometheusGraph;

  const graphElement = () => document.querySelector('.prometheus-graph');

  preloadFixtures(fixtureName);

  beforeEach((done) => {
    // Setup the view
    loadFixtures(fixtureName);

    d3.selectAll('.prometheus-graph')
      .append('g')
      .attr('class', 'graph-container');

    prometheusGraph = new PrometheusGraph();
    deployment = new Deployments(1000, 500);

    spyOn(prometheusGraph, 'init');
    spyOn($, 'ajax').and.callFake(() => {
      const d = $.Deferred();
      d.resolve({
        deployments: [{
          id: 1,
          created_at: deployment.chartData[10].time,
          sha: 'testing',
          tag: false,
          ref: {
            name: 'testing',
          },
        }, {
          id: 2,
          created_at: deployment.chartData[15].time,
          sha: '',
          tag: true,
          ref: {
            name: 'tag',
          },
        }],
      });

      setTimeout(done);

      return d.promise();
    });

    prometheusGraph.configureGraph();
    prometheusGraph.transformData(prometheusMockData.metrics);

    deployment.init(prometheusGraph.graphSpecificProperties.memory_values.data);
  });

  it('creates line on graph for deploment', () => {
    expect(
      graphElement().querySelectorAll('.deployment-line').length,
    ).toBe(2);
  });

  it('creates hidden deploy boxes', () => {
    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box').length,
    ).toBe(2);
  });

  it('hides the info boxes by default', () => {
    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box.hidden').length,
    ).toBe(2);
  });

  it('shows sha short code when tag is false', () => {
    expect(
      graphElement().querySelector('.deploy-info-1-cpu_values .js-deploy-info-box').textContent.trim(),
    ).toContain('testin');
  });

  it('shows ref name when tag is true', () => {
    expect(
      graphElement().querySelector('.deploy-info-2-cpu_values .js-deploy-info-box').textContent.trim(),
    ).toContain('tag');
  });

  it('shows info box when moving mouse over line', () => {
    deployment.mouseOverDeployInfo(deployment.data[0].xPos, 'cpu_values');

    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box.hidden').length,
    ).toBe(1);

    expect(
      graphElement().querySelector('.deploy-info-1-cpu_values .js-deploy-info-box.hidden'),
    ).toBeNull();
  });

  it('hides previously visible info box when moving mouse away', () => {
    deployment.mouseOverDeployInfo(500, 'cpu_values');

    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box.hidden').length,
    ).toBe(2);

    expect(
      graphElement().querySelector('.deploy-info-1-cpu_values .js-deploy-info-box.hidden'),
    ).not.toBeNull();
  });

  describe('refText', () => {
    it('returns shortened SHA', () => {
      expect(
        Deployments.refText({
          tag: false,
          sha: '123456789',
        }),
      ).toBe('123456');
    });

    it('returns tag name', () => {
      expect(
        Deployments.refText({
          tag: true,
          ref: 'v1.0',
        }),
      ).toBe('v1.0');
    });
  });
});
