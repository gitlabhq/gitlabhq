import d3 from 'd3';
import PrometheusGraph from '~/monitoring/prometheus_graph';
import Deployments from '~/monitoring/deployments';
import { prometheusMockData } from './prometheus_mock_data';

fdescribe('Metrics deployments', () => {
  const fixtureName = 'static/environments/metrics.html.raw';
  let deployment;
  let prometheusGraph;

  const createDeploymentMockData = (done) => {
    return {
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
    };
  };

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
      d.resolve(createDeploymentMockData());

      setTimeout(done);

      return d.promise();
    });

    prometheusGraph.transformData(prometheusMockData.metrics);

    deployment.init(prometheusGraph.data.memory_values);
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
      graphElement().querySelector('.deploy-info-1 .js-deploy-info-box').textContent.trim(),
    ).toContain('testin');
  });

  it('shows ref name when tag is true', () => {
    expect(
      graphElement().querySelector('.deploy-info-2 .js-deploy-info-box').textContent.trim(),
    ).toContain('tag');
  });

  it('shows info box when moving mouse over line', () => {
    deployment.mouseOverDeployInfo(deployment.data[0].xPos);

    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box.hidden').length,
    ).toBe(1);

    expect(
      graphElement().querySelector('.deploy-info-1 .js-deploy-info-box.hidden'),
    ).toBeNull();
  });

  it('hides previously visible info box when moving mouse away', () => {
    deployment.mouseOverDeployInfo(500);

    expect(
      graphElement().querySelectorAll('.prometheus-graph .js-deploy-info-box.hidden').length,
    ).toBe(2);

    expect(
      graphElement().querySelector('.deploy-info-1 .js-deploy-info-box.hidden'),
    ).not.toBeNull();
  });
});
