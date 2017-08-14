import $ from 'jquery';
import { addEventsForNonVueEls, confirmUnload, handleDropdownChange } from '~/repo/repo_index';
import RepoStore from '~/repo/stores/repo_store';

describe('Repo index', () => {
  describe('addEventsForNonVueEls', () => {
    it('registers a change handler', () => {
      spyOn($.prototype, 'on');

      addEventsForNonVueEls();

      expect($.prototype.on).toHaveBeenCalledWith('change', '.dropdown', handleDropdownChange);

      expect(window.onbeforeunload).toBe(confirmUnload);
    });
  });

  describe('confirmUnload', () => {
    const confirmationString = 'Are you sure you want to lose unsaved changes?';
    const openedFiles = [
      {
        id: 0,
        changed: true,
      },
      {
        id: 1,
        changed: true,
      },
      {
        id: 2,
        changed: false,
      },
    ];

    it('returns undefined if no changed files', () => {
      RepoStore.openedFiles = [];

      expect(confirmUnload()).toBeUndefined();
    });

    it('returns confirmation string', () => {
      RepoStore.openedFiles = openedFiles;

      expect(confirmUnload()).toEqual(confirmationString);
    });

    it('sets event.returnValue to confirmation string if is event', () => {
      const event = { returnValue: '' };
      RepoStore.openedFiles = openedFiles;

      expect(confirmUnload(event)).toEqual(confirmationString);
      expect(event.returnValue).toEqual(confirmationString);
    });
  });

  describe('handleDropdownChange', () => {
    it('queries for ref input, sets targetBranch and isTargetBranchNew', () => {
      const value = 'value';
      const dataInput = 'true';
      const refInput = jasmine.createSpyObj('refInput', ['val', 'attr']);

      refInput.val.and.returnValue(value);
      refInput.attr.and.returnValue(dataInput);
      spyOn($.fn, 'find').and.returnValue(refInput);

      handleDropdownChange();

      expect($.fn.find).toHaveBeenCalledWith('.project-refs-target-form input[name="ref"]');
      expect(refInput.val).toHaveBeenCalled();
      expect(refInput.attr).toHaveBeenCalledWith('data-input');
      expect(RepoStore.targetBranch).toEqual(value);
      expect(RepoStore.isTargetBranchNew).toEqual(!!dataInput);
    });
  });
});
