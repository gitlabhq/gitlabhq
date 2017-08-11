import $ from 'jquery';
import { addEventsForNonVueEls, confirmUnload, handleDropdownChange } from '~/repo/index';
// import RepoStore from '~/repo/stores/repo_store';

fdescribe('Repo index', () => {
  describe('addEventsForNonVueEls', () => {
    it('registers a change handler', () => {
      spyOn($.prototype, 'on');

      addEventsForNonVueEls();

      expect($.prototype.on).toHaveBeenCalledWith('change', '.dropdown', handleDropdownChange);

      expect(window.onbeforeunload).toBe(confirmUnload);
    });
  });
});
