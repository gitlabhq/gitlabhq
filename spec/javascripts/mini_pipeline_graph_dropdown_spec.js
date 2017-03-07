/* eslint-disable no-new */

require('~/flash');
require('~/mini_pipeline_graph_dropdown');

(() => {
  describe('Mini Pipeline Graph Dropdown', () => {
    preloadFixtures('static/mini_dropdown_graph.html.raw');

    beforeEach(() => {
      loadFixtures('static/mini_dropdown_graph.html.raw');
    });

    describe('When is initialized', () => {
      it('should initialize without errors when no options are given', () => {
        const miniPipelineGraph = new window.gl.MiniPipelineGraph();

        expect(miniPipelineGraph.dropdownListSelector).toEqual('.js-builds-dropdown-container');
      });

      it('should set the container as the given prop', () => {
        const container = '.foo';

        const miniPipelineGraph = new window.gl.MiniPipelineGraph({ container });

        expect(miniPipelineGraph.container).toEqual(container);
      });
    });

    describe('When dropdown is clicked', () => {
      it('should call getBuildsList', () => {
        const getBuildsListSpy = spyOn(gl.MiniPipelineGraph.prototype, 'getBuildsList').and.callFake(function () {});

        new gl.MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

        document.querySelector('.js-builds-dropdown-button').click();

        expect(getBuildsListSpy).toHaveBeenCalled();
      });

      it('should make a request to the endpoint provided in the html', () => {
        const ajaxSpy = spyOn($, 'ajax').and.callFake(function () {});

        new gl.MiniPipelineGraph({ container: '.js-builds-dropdown-tests' }).bindEvents();

        document.querySelector('.js-builds-dropdown-button').click();
        expect(ajaxSpy.calls.allArgs()[0][0].url).toEqual('foobar');
      });
    });
  });
})();
