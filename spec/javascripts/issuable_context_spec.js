import '~/issuable_context';

fdescribe('IssuableContext', () => {
  describe('toggleHiddenParticipants', () => {
    beforeEach(() => {

    });

    fit('calls loadCheck if lazyLoader is set', () => {
      gl.lazyLoader = jasmine.createSpyObj('lazyLoader', ['loadCheck']);
      const event = {};

      IssuableContext.prototype.toggleHiddenParticipants(event);

      expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
    });

    it('does not call loadCheck if lazyLoader is not set', () => {
      gl.lazyLoader = undefined;
      const event = {};

      IssuableContext.prototype.toggleHiddenParticipants(event);

      expect(gl.lazyLoader.loadCheck).not.toHaveBeenCalled();
    });

    afterEach(() => {
      gl.lazyLoader = undefined;
    });
  });
});
