import Dispatcher from '~/dispatcher';

fdescribe('Dispatcher', () => {
  let dispatcher;
  describe('initPageScripts', () => {
    describe('projects:issues:index', () => {
      beforeEach(() => {
        dispatcher = new Dispatcher();
        spyOn($.prototype, 'attr').and.returnValue('projects:issues:index');
        spyOn(gl, 'FilteredSearchManager');
      });

      it('doesnt instantiate FilteredSearchManager if element is not found', () => {
        spyOn(document, 'querySelector').and.returnValue(false);

        dispatcher.initPageScripts();

        expect(gl.FilteredSearchManager).not.toHaveBeenCalled();
      });

      it('instantiates FilteredSearchManager if element is found', () => {
        spyOn(document, 'querySelector').and.returnValue(document.createElement('div'));

        dispatcher.initPageScripts();

        expect(gl.FilteredSearchManager).toHaveBeenCalled();
      });
    });
  });
});
