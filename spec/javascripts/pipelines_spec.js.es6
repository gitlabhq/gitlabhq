require('~/pipelines');

// Fix for phantomJS
if (!Element.prototype.matches && Element.prototype.webkitMatchesSelector) {
  Element.prototype.matches = Element.prototype.webkitMatchesSelector;
}

(() => {
  describe('Pipelines', () => {
    preloadFixtures('static/pipeline_graph.html.raw');

    beforeEach(() => {
      loadFixtures('static/pipeline_graph.html.raw');
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
