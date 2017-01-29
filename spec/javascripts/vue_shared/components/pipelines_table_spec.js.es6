/* global pipeline */

//= require vue
//= require vue_shared/components/pipelines_table
//= require commit/pipelines/mock_data
//= require lib/utils/datetime_utility

describe('Pipelines Table', () => {
  preloadFixtures('static/environments/element.html.raw');

  beforeEach(() => {
    loadFixtures('static/environments/element.html.raw');
  });

  describe('table', () => {
    let component;
    beforeEach(() => {
      component = new gl.pipelines.PipelinesTableComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          pipelines: [],
          svgs: {},
        },
      });
    });

    it('should render a table', () => {
      expect(component.$el).toEqual('TABLE');
    });

    it('should render table head with correct columns', () => {
      expect(component.$el.querySelector('th.js-pipeline-status').textContent).toEqual('Status');
      expect(component.$el.querySelector('th.js-pipeline-info').textContent).toEqual('Pipeline');
      expect(component.$el.querySelector('th.js-pipeline-commit').textContent).toEqual('Commit');
      expect(component.$el.querySelector('th.js-pipeline-stages').textContent).toEqual('Stages');
      expect(component.$el.querySelector('th.js-pipeline-date').textContent).toEqual('');
      expect(component.$el.querySelector('th.js-pipeline-actions').textContent).toEqual('');
    });
  });

  describe('without data', () => {
    it('should render an empty table', () => {
      const component = new gl.pipelines.PipelinesTableComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          pipelines: [],
          svgs: {},
        },
      });
      expect(component.$el.querySelectorAll('tbody tr').length).toEqual(0);
    });
  });

  describe('with data', () => {
    it('should render rows', () => {
      const component = new gl.pipelines.PipelinesTableComponent({
        el: document.querySelector('.test-dom-element'),
        propsData: {
          pipelines: [pipeline],
          svgs: {},
        },
      });

      expect(component.$el.querySelectorAll('tbody tr').length).toEqual(1);
    });
  });
});
