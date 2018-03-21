import Vue from 'vue';
import MemoryGraph from '~/vue_shared/components/memory_graph.vue';
import { mockMetrics, mockMedian, mockMedianIndex } from './mock_data';

const defaultHeight = '25';
const defaultWidth = '100';

const createComponent = () => {
  const Component = Vue.extend(MemoryGraph);

  return new Component({
    el: document.createElement('div'),
    propsData: {
      metrics: [],
      deploymentTime: 0,
      width: '',
      height: '',
      pathD: '',
      pathViewBox: '',
      dotX: '',
      dotY: '',
    },
  });
};

describe('MemoryGraph', () => {
  let vm;
  let el;

  beforeEach(() => {
    vm = createComponent();
    el = vm.$el;
  });

  describe('data', () => {
    it('should have default data', () => {
      const data = MemoryGraph.data();
      const dataValidator = (dataItem, expectedType, defaultVal) => {
        expect(typeof dataItem).toBe(expectedType);
        expect(dataItem).toBe(defaultVal);
      };

      dataValidator(data.pathD, 'string', '');
      dataValidator(data.pathViewBox, 'string', '');
      dataValidator(data.dotX, 'string', '');
      dataValidator(data.dotY, 'string', '');
    });
  });

  describe('computed', () => {
    describe('getFormattedMedian', () => {
      it('should show human readable median value based on provided median timestamp', () => {
        vm.deploymentTime = mockMedian;
        const formattedMedian = vm.getFormattedMedian;
        expect(formattedMedian.indexOf('Deployed') > -1).toBeTruthy();
        expect(formattedMedian.indexOf('ago') > -1).toBeTruthy();
      });
    });
  });

  describe('methods', () => {
    describe('getMedianMetricIndex', () => {
      it('should return index of closest metric timestamp to that of median', () => {
        const matchingIndex = vm.getMedianMetricIndex(mockMedian, mockMetrics);
        expect(matchingIndex).toBe(mockMedianIndex);
      });
    });

    describe('getGraphPlotValues', () => {
      it('should return Object containing values to plot graph', () => {
        const plotValues = vm.getGraphPlotValues(mockMedian, mockMetrics);
        expect(plotValues.pathD).toBeDefined();
        expect(Array.isArray(plotValues.pathD)).toBeTruthy();

        expect(plotValues.pathViewBox).toBeDefined();
        expect(typeof plotValues.pathViewBox).toBe('object');

        expect(plotValues.dotX).toBeDefined();
        expect(typeof plotValues.dotX).toBe('number');

        expect(plotValues.dotY).toBeDefined();
        expect(typeof plotValues.dotY).toBe('number');
      });
    });
  });

  describe('template', () => {
    it('should render template elements correctly', () => {
      expect(el.classList.contains('memory-graph-container')).toBeTruthy();
      expect(el.querySelector('svg')).toBeDefined();
    });

    it('should render graph when renderGraph is called internally', (done) => {
      const { pathD, pathViewBox, dotX, dotY } = vm.getGraphPlotValues(mockMedian, mockMetrics);
      vm.height = defaultHeight;
      vm.width = defaultWidth;
      vm.pathD = `M ${pathD}`;
      vm.pathViewBox = `0 0 ${pathViewBox.lineWidth} ${pathViewBox.diff}`;
      vm.dotX = dotX;
      vm.dotY = dotY;

      Vue.nextTick(() => {
        const svgEl = el.querySelector('svg');
        expect(svgEl).toBeDefined();
        expect(svgEl.getAttribute('height')).toBe(defaultHeight);
        expect(svgEl.getAttribute('width')).toBe(defaultWidth);

        const pathEl = el.querySelector('path');
        expect(pathEl).toBeDefined();
        expect(pathEl.getAttribute('d')).toBe(`M ${pathD}`);
        expect(pathEl.getAttribute('viewBox')).toBe(`0 0 ${pathViewBox.lineWidth} ${pathViewBox.diff}`);

        const circleEl = el.querySelector('circle');
        expect(circleEl).toBeDefined();
        expect(circleEl.getAttribute('r')).toBe('1.5');
        expect(circleEl.getAttribute('tranform')).toBe('translate(0 -1)');
        expect(circleEl.getAttribute('cx')).toBe(`${dotX}`);
        expect(circleEl.getAttribute('cy')).toBe(`${dotY}`);
        done();
      });
    });
  });
});
