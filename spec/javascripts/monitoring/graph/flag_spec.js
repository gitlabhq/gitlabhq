import Vue from 'vue';
import GraphFlag from '~/monitoring/components/graph/flag.vue';
import { deploymentData } from '../mock_data';

const createComponent = (propsData) => {
  const Component = Vue.extend(GraphFlag);

  return new Component({
    propsData,
  }).$mount();
};

const defaultValuesComponent = {
  currentXCoordinate: 200,
  currentYCoordinate: 100,
  currentFlagPosition: 100,
  currentData: {
    time: new Date('2017-06-04T18:17:33.501Z'),
    value: '1.49609375',
  },
  graphHeight: 300,
  graphHeightOffset: 120,
  showFlagContent: true,
  realPixelRatio: 1,
  timeSeries: [{
    values: [{
      time: new Date('2017-06-04T18:17:33.501Z'),
      value: '1.49609375',
    }],
  }],
  unitOfDisplay: 'ms',
  currentDataIndex: 0,
  legendTitle: 'Average',
};

const deploymentFlagData = {
  ...deploymentData[0],
  ref: deploymentData[0].ref.name,
  xPos: 10,
  time: new Date(deploymentData[0].created_at),
};

describe('GraphFlag', () => {
  let component;

  it('has a line at the currentXCoordinate', () => {
    component = createComponent(defaultValuesComponent);

    expect(component.$el.style.left)
      .toEqual(`${70 + component.currentXCoordinate}px`);
  });

  describe('Deployment flag', () => {
    it('shows a deployment flag when deployment data provided', () => {
      const deploymentFlagComponent = createComponent({
        ...defaultValuesComponent,
        deploymentFlagData,
      });

      expect(
        deploymentFlagComponent.$el.querySelector('.popover-title'),
      ).toContainText('Deployed');
    });

    it('contains the ref when a tag is available', () => {
      const deploymentFlagComponent = createComponent({
        ...defaultValuesComponent,
        deploymentFlagData: {
          ...deploymentFlagData,
          sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
          tag: true,
          ref: '1.0',
        },
      });

      expect(
        deploymentFlagComponent.$el.querySelector('.deploy-meta-content'),
      ).toContainText('f5bcd1d9');

      expect(
        deploymentFlagComponent.$el.querySelector('.deploy-meta-content'),
      ).toContainText('1.0');
    });

    it('does not contain the ref when a tag is unavailable', () => {
      const deploymentFlagComponent = createComponent({
        ...defaultValuesComponent,
        deploymentFlagData: {
          ...deploymentFlagData,
          sha: 'f5bcd1d9dac6fa4137e2510b9ccd134ef2e84187',
          tag: false,
          ref: '1.0',
        },
      });

      expect(
        deploymentFlagComponent.$el.querySelector('.deploy-meta-content'),
      ).toContainText('f5bcd1d9');

      expect(
        deploymentFlagComponent.$el.querySelector('.deploy-meta-content'),
      ).not.toContainText('1.0');
    });
  });

  describe('Computed props', () => {
    beforeEach(() => {
      component = createComponent(defaultValuesComponent);
    });

    it('formatTime', () => {
      expect(component.formatTime).toMatch(/\d:17PM/);
    });

    it('formatDate', () => {
      expect(component.formatDate).toEqual('Sun, Jun 4');
    });

    it('cursorStyle', () => {
      expect(component.cursorStyle).toEqual({
        top: '20px',
        left: '270px',
        height: '180px',
      });
    });

    it('flagOrientation', () => {
      expect(component.flagOrientation).toEqual('left');
    });
  });
});
