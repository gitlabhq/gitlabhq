import Pipelines from '~/pipelines';

// Fix for phantomJS
if (!Element.prototype.matches && Element.prototype.webkitMatchesSelector) {
  Element.prototype.matches = Element.prototype.webkitMatchesSelector;
}

describe('Pipelines', () => {
  preloadFixtures('static/pipeline_graph.html.raw');

  beforeEach(() => {
    loadFixtures('static/pipeline_graph.html.raw');
  });

  it('should be defined', () => {
    expect(Pipelines).toBeDefined();
  });

  it('should create a `Pipelines` instance without options', () => {
    expect(() => { new Pipelines(); }).not.toThrow(); //eslint-disable-line
  });
});
