import StickyTabs from '~/sticky_tabs';

describe('StickyTabs', () => {
  const stickyTabsEl = {};
  const unstickyTabsEl = { offsetHeight: 1 };
  let stickyTabs;

  beforeEach(() => {
    stickyTabs = new StickyTabs(stickyTabsEl, unstickyTabsEl);
  });

  afterEach(() => {
    stickyTabs.unbindEvents();
  });

  describe('class constructor', () => {
    it('sets stickyTabs, unstickyTabs, unstickyTabsHeight and eventListeners', () => {
      expect(stickyTabs.stickyTabs).toBe(stickyTabsEl);
      expect(stickyTabs.unstickyTabs).toBe(unstickyTabsEl);
      expect(stickyTabs.unstickyTabsHeight).toBe(unstickyTabsEl.offsetHeight);
      expect(stickyTabs.eventListeners).toEqual({});
    });
  });

  describe('bindEvents', () => {
    it('sets eventListeners.handleStickyTabs and add as scroll listener', () => {
      spyOn(document, 'addEventListener');

      stickyTabs.bindEvents();

      expect(stickyTabs.eventListeners.handleStickyTabs).toEqual(jasmine.any(Function));
      expect(document.addEventListener).toHaveBeenCalledWith('scroll', stickyTabs.eventListeners.handleStickyTabs);
    });
  });

  describe('unbindEvents', () => {
    it('removes eventListeners.handleStickyTabs scroll listener', () => {
      spyOn(document, 'removeEventListener');

      stickyTabs.unbindEvents();

      expect(document.removeEventListener).toHaveBeenCalledWith('scroll', stickyTabs.eventListeners.handleStickyTabs);
    });
  });

  describe('handleStickyTabs', () => {
    beforeEach(() => {
      stickyTabsEl.classList = jasmine.createSpyObj('classList', ['add', 'remove']);
      unstickyTabsEl.classList = jasmine.createSpyObj('classList', ['add', 'remove']);
      unstickyTabsEl.getBoundingClientRect = jasmine.createSpy('getBoundingClientRect');
    });

    it('adds .invisible to unstickyTabs and removes .hide from stickyTabs if viewport is below unstickyTabs', () => {
      unstickyTabsEl.getBoundingClientRect.and.returnValue({ top: 0 });

      stickyTabs.handleStickyTabs();

      expect(unstickyTabsEl.classList.add).toHaveBeenCalledWith('invisible');
      expect(stickyTabsEl.classList.remove).toHaveBeenCalledWith('hide');
    });

    it('removes .invisible from unstickyTabs and adds .hide to stickyTabs if viewport is above unstickyTabs', () => {
      unstickyTabsEl.getBoundingClientRect.and.returnValue({ top: 2 });

      stickyTabs.handleStickyTabs();

      expect(unstickyTabsEl.classList.remove).toHaveBeenCalledWith('invisible');
      expect(stickyTabsEl.classList.add).toHaveBeenCalledWith('hide');
    });
  });
});
