import '~/merge_request_tabs';
import StickyTabs from '~/sticky_tabs';

describe('MergeRequestTabs units', () => {
  const stickyTabs = {};
  const unstickyTabs = {};
  const options = {
    stickyTabs,
    unstickyTabs,
  };
  let mergeRequestTabs;

  beforeEach(() => {
    options.unstickyTabs.getBoundingClientRect = jasmine.createSpy('getBoundingClientRect').and.returnValue({ top: 0 });
    options.stickyTabs.classList = jasmine.createSpyObj('classList', ['add', 'remove']);
    options.unstickyTabs.classList = jasmine.createSpyObj('classList', ['add', 'remove']);
  });

  afterEach(() => {
    mergeRequestTabs.unbindEvents();
  });

  describe('class constructor', () => {
    it('instantiates StickyTabs if tabs are provided', () => {
      mergeRequestTabs = new gl.MergeRequestTabs(options);

      expect(mergeRequestTabs.stickyTabs).toEqual(jasmine.any(StickyTabs));
    });

    it('does not instantiate StickyTabs if no tabs are provided', () => {
      mergeRequestTabs = new gl.MergeRequestTabs();

      expect(mergeRequestTabs.stickyTabs).toBeUndefined();
    });
  });

  describe('bindEvents', () => {
    beforeEach(() => {
      spyOn(StickyTabs.prototype, 'bindEvents');
    });

    it('calls stickyTabs.bindEvents if stickyTabs is set', () => {
      mergeRequestTabs = new gl.MergeRequestTabs(options);
      mergeRequestTabs.bindEvents();

      expect(StickyTabs.prototype.bindEvents).toHaveBeenCalled();
    });

    it('does not call stickyTabs.bindEvents if stickyTabs is not set', () => {
      mergeRequestTabs = new gl.MergeRequestTabs();
      mergeRequestTabs.bindEvents();

      expect(StickyTabs.prototype.bindEvents).not.toHaveBeenCalled();
    });
  });

  describe('unbindEvents', () => {
    beforeEach(() => {
      spyOn(StickyTabs.prototype, 'unbindEvents');
    });

    it('calls stickyTabs.unbindEvents if stickyTabs is set', () => {
      mergeRequestTabs = new gl.MergeRequestTabs(options);
      mergeRequestTabs.unbindEvents();

      expect(StickyTabs.prototype.unbindEvents).toHaveBeenCalled();
    });

    it('does not call stickyTabs.unbindEvents if stickyTabs is not set', () => {
      mergeRequestTabs = new gl.MergeRequestTabs();
      mergeRequestTabs.unbindEvents();

      expect(StickyTabs.prototype.unbindEvents).not.toHaveBeenCalled();
    });
  });
});
