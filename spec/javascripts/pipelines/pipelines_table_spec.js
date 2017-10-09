import Vue from 'vue';
import pipelinesTableComp from '~/pipelines/components/pipelines_table.vue';
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
          autoDevopsHelpPath: 'foo',
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
      expect(component.$el.querySelector('.table-section.js-pipeline-status').textContent.trim()).toEqual('Status');
      expect(component.$el.querySelector('.table-section.js-pipeline-info').textContent.trim()).toEqual('Pipeline');
      expect(component.$el.querySelector('.table-section.js-pipeline-commit').textContent.trim()).toEqual('Commit');
      expect(component.$el.querySelector('.table-section.js-pipeline-stages').textContent.trim()).toEqual('Stages');
    });
  });

  describe('without data', () => {
    it('should render an empty table', () => {
      const component = new PipelinesTableComponent({
        propsData: {
          pipelines: [],
          autoDevopsHelpPath: 'foo',
        },
      }).$mount();
      expect(component.$el.querySelectorAll('.commit.gl-responsive-table-row').length).toEqual(0);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      const component = new PipelinesTableComponent({
        propsData: {
          pipelines: [pipeline],
          autoDevopsHelpPath: 'foo',
        },
      }).$mount();

      expect(component.$el.querySelectorAll('.commit.gl-responsive-table-row').length).toEqual(1);
    });
  });
});
