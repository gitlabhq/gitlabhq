import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import BarChart from '~/vue_shared/components/bar_chart.vue';

function getRandomArbitrary(min, max) {
  return Math.random() * (max - min) + min;
}

function generateRandomData(dataNumber) {
  const randomGraphData = [];

  for (let i = 1; i <= dataNumber; i += 1) {
    randomGraphData.push({
      name: `random ${i}`,
      value: parseInt(getRandomArbitrary(1, 8), 10),
    });
  }

  return randomGraphData;
}

describe('Bar chart component', () => {
  let barChart;
  const graphData = generateRandomData(10);

  beforeEach(() => {
    const BarChartComponent = Vue.extend(BarChart);

    barChart = mountComponent(BarChartComponent, {
      graphData,
      yAxisLabel: 'data',
    });
  });

  afterEach(() => {
    barChart.$destroy();
  });

  it('calculates the padding for even distribution across bars', () => {
    barChart.vbWidth = 1000;
    const result = barChart.calculatePadding(30);

    // since padding can't be higher than 1 and lower than 0
    // for more info: https://github.com/d3/d3-scale#band-scales
    expect(result).not.toBeLessThan(0);
    expect(result).not.toBeGreaterThan(1);
  });

  it('formats the tooltip title', () => {
    const tooltipTitle = barChart.setTooltipTitle(barChart.graphData[0]);

    expect(tooltipTitle).toContain('random 1:');
  });

  it('has a translates the bar graphs on across the X axis', () => {
    barChart.panX = 100;

    expect(barChart.barTranslationTransform).toEqual('translate(100, 0)');
  });

  it('translates the scroll indicator to the far right side', () => {
    barChart.vbWidth = 500;

    expect(barChart.scrollIndicatorTransform).toEqual('translate(420, 0)');
  });

  it('translates the x-axis to the bottom of the viewbox and pan coordinates', () => {
    barChart.panX = 100;
    barChart.vbHeight = 250;

    expect(barChart.xAxisLocation).toEqual('translate(100, 250)');
  });

  it('rotates the x axis labels a total of 90 degress (CCW)', () => {
    const xAxisLabel = barChart.$el.querySelector('.x-axis').querySelectorAll('text')[0];

    expect(xAxisLabel.getAttribute('transform')).toEqual('rotate(-90)');
  });
});
