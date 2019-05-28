import Pipelines from '~/pipelines';

describe('Pipelines', () => {
  preloadFixtures('static/pipeline_graph.html');

  beforeEach(() => {
    loadFixtures('static/pipeline_graph.html');
  });

  it('should be defined', () => {
    expect(Pipelines).toBeDefined();
  });

  it('should create a `Pipelines` instance without options', () => {
    expect(() => {
      new Pipelines(); // eslint-disable-line no-new
    }).not.toThrow();
  });
});
