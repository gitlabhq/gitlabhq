/* global IssuableContext */
import '~/issuable_context';

describe('IssuableContext', () => {
  describe('toggleHiddenParticipants', () => {
    const event = jasmine.createSpyObj('event', ['preventDefault']);

    it('calls loadCheck if lazyLoader is set', () => {
      gl.lazyLoader = jasmine.createSpyObj('lazyLoader', ['loadCheck']);

      IssuableContext.prototype.toggleHiddenParticipants(event);

      expect(gl.lazyLoader.loadCheck).toHaveBeenCalled();
    });

    it('does not throw if lazyLoader is not set', () => {
      gl.lazyLoader = undefined;

      const toggle = IssuableContext.prototype.toggleHiddenParticipants.bind(null, event);

      expect(toggle).not.toThrow();
    });

    afterEach(() => {
      gl.lazyLoader = undefined;
    });
  });
});
