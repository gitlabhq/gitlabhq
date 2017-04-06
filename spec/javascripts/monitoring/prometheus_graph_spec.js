import 'jquery';
import PrometheusGraph from '~/monitoring/prometheus_graph';
import { prometheusMockData } from './prometheus_mock_data';

describe('PrometheusGraph', () => {
  const fixtureName = 'static/environments/metrics.html.raw';
  const prometheusGraphContainer = '.prometheus-graph';
  const prometheusGraphContents = `${prometheusGraphContainer}[graph-type=cpu_values]`;

  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    $('.prometheus-container').data('has-metrics', 'true');
    this.prometheusGraph = new PrometheusGraph();
    const self = this;
    const fakeInit = (metricsResponse) => {
      self.prometheusGraph.transformData(metricsResponse);
      self.prometheusGraph.createGraph();
    };
    spyOn(this.prometheusGraph, 'init').and.callFake(fakeInit);
  });

  it('initializes graph properties', () => {
    // Test for the measurements
    expect(this.prometheusGraph.margin).toBeDefined();
    expect(this.prometheusGraph.marginLabelContainer).toBeDefined();
    expect(this.prometheusGraph.originalWidth).toBeDefined();
    expect(this.prometheusGraph.originalHeight).toBeDefined();
    expect(this.prometheusGraph.height).toBeDefined();
    expect(this.prometheusGraph.width).toBeDefined();
    expect(this.prometheusGraph.backOffRequestCounter).toBeDefined();
    // Test for the graph properties (colors, radius, etc.)
    expect(this.prometheusGraph.graphSpecificProperties).toBeDefined();
    expect(this.prometheusGraph.commonGraphProperties).toBeDefined();
  });

  it('transforms the data', () => {
    this.prometheusGraph.init(prometheusMockData.metrics);
    Object.keys(this.prometheusGraph.graphSpecificProperties, (key) => {
      const graphProps = this.prometheusGraph.graphSpecificProperties[key];
      expect(graphProps.data).toBeDefined();
      expect(graphProps.data.length).toBe(121);
    });
  });

  it('creates two graphs', () => {
    this.prometheusGraph.init(prometheusMockData.metrics);
    expect($(prometheusGraphContainer).length).toBe(2);
  });

  describe('Graph contents', () => {
    beforeEach(() => {
      this.prometheusGraph.init(prometheusMockData.metrics);
    });

    it('has axis, an area, a line and a overlay', () => {
      const $graphContainer = $(prometheusGraphContents).find('.x-axis').parent();
      expect($graphContainer.find('.x-axis')).toBeDefined();
      expect($graphContainer.find('.y-axis')).toBeDefined();
      expect($graphContainer.find('.prometheus-graph-overlay')).toBeDefined();
      expect($graphContainer.find('.metric-line')).toBeDefined();
      expect($graphContainer.find('.metric-area')).toBeDefined();
    });

    it('has legends, labels and an extra axis that labels the metrics', () => {
      const $prometheusGraphContents = $(prometheusGraphContents);
      const $axisLabelContainer = $(prometheusGraphContents).find('.label-x-axis-line').parent();
      expect($prometheusGraphContents.find('.label-x-axis-line')).toBeDefined();
      expect($prometheusGraphContents.find('.label-y-axis-line')).toBeDefined();
      expect($prometheusGraphContents.find('.label-axis-text')).toBeDefined();
      expect($prometheusGraphContents.find('.rect-axis-text')).toBeDefined();
      expect($axisLabelContainer.find('rect').length).toBe(3);
      expect($axisLabelContainer.find('text').length).toBe(4);
    });
  });
});

describe('PrometheusGraphs UX states', () => {
  const fixtureName = 'static/environments/metrics.html.raw';
  preloadFixtures(fixtureName);

  beforeEach(() => {
    loadFixtures(fixtureName);
    this.prometheusGraph = new PrometheusGraph();
  });

  it('shows a specified state', () => {
    this.prometheusGraph.state = '.js-getting-started';
    this.prometheusGraph.updateState();
    const $state = $('.js-getting-started');
    expect($state).toBeDefined();
    expect($('.state-title', $state)).toBeDefined();
    expect($('.state-svg', $state)).toBeDefined();
    expect($('.state-description', $state)).toBeDefined();
    expect($('.state-button', $state)).toBeDefined();
  });
});
