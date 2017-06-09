import Vue from 'vue';
import pipelinesTableComp from '~/vue_shared/components/pipelines_table';
import '~/lib/utils/datetime_utility';

describe('Pipelines Table', () => {
  const jsonFixtureName = 'pipelines/pipelines.json';

  let pipeline;
  let PipelinesTableComponent;

  preloadFixtures(jsonFixtureName);

  beforeEach(() => {
    PipelinesTableComponent = Vue.extend(pipelinesTableComp);
    const pipelines = getJSONFixture(jsonFixtureName).pipelines;
    pipeline = pipelines.find(p => p.id === 1);
  });

  describe('table', () => {
    let component;
    beforeEach(() => {
      component = new PipelinesTableComponent({
        propsData: {
          pipelines: [],
          service: {},
        },
      }).$mount();
    });

    afterEach(() => {
      component.$destroy();
    });

    it('should render a table', () => {
      expect(component.$el.getAttribute('class')).toContain('ci-table');
    });

    it('should render table head with correct columns', () => {
      expect(component.$el.querySelector('.table-section.js-pipeline-status').textContent).toEqual('Status');
      expect(component.$el.querySelector('.table-section.js-pipeline-info').textContent).toEqual('Pipeline');
      expect(component.$el.querySelector('.table-section.js-pipeline-commit').textContent).toEqual('Commit');
      expect(component.$el.querySelector('.table-section.js-pipeline-stages').textContent).toEqual('Stages');
    });
  });

  describe('without data', () => {
    it('should render an empty table', () => {
      const component = new PipelinesTableComponent({
        propsData: {
          pipelines: [],
          service: {},
        },
      }).$mount();
      expect(component.$el.querySelectorAll('.commit.gl-responsive-table-row').length).toEqual(0);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      const component = new PipelinesTableComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          pipelines: [pipeline],
          service: {},
        },
      }).$mount();

      expect(component.$el.querySelectorAll('.commit.gl-responsive-table-row').length).toEqual(1);
    });
  });
});
