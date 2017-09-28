/* global IssuableContext */
import '~/issuable_context';

describe('IssuableContext', () => {
  describe('toggleHiddenParticipants', () => {
    const event = jasmine.createSpyObj('event', ['preventDefault']);

    afterEach(() => {
      gl.lazyLoader = undefined;
    });

    it('calls loadCheck if lazyLoader is set', () => {
      gl.lazyLoader = jasmine.createSpyObj('lazyLoader', ['loadCheck']);

      IssuableContext.prototype.toggleHiddenParticipants(event);

      expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
    });

    it('does not throw if lazyLoader is not defined', () => {
      gl.lazyLoader = undefined;

      const toggle = IssuableContext.prototype.toggleHiddenParticipants.bind(null, event);

      expect(toggle).not.toThrow();
    });
  });
});
