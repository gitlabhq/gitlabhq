//= require pipelines

(() => {
  describe('Pipelines', () => {
    fixture.preload('static/pipeline_graph.html.raw');

    beforeEach(() => {
      fixture.load('static/pipeline_graph.html.raw');
    });

    it('should be defined', () => {
      expect(window.gl.Pipelines).toBeDefined();
    });

    it('should create a `Pipelines` instance without options', () => {
      expect(() => { new window.gl.Pipelines(); }).not.toThrow(); //eslint-disable-line
    });

    it('should create a `Pipelines` instance with options', () => {
      const pipelines = new window.gl.Pipelines({ foo: 'bar' });

      expect(pipelines.pipelineGraph).toBeDefined();
    });
  });
})();
