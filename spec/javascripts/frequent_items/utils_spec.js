import { GlBreakpointInstance as bp } from '@gitlab/ui/dist/utils';
import { isMobile, getTopFrequentItems, updateExistingFrequentItem } from '~/frequent_items/utils';
import { HOUR_IN_MS, FREQUENT_ITEMS } from '~/frequent_items/constants';
import { mockProject, unsortedFrequentItems, sortedFrequentItems } from './mock_data';

describe('Frequent Items utils spec', () => {
  describe('isMobile', () => {
    it('returns true when the screen is medium ', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');

      expect(isMobile()).toBe(true);
    });

    it('returns true when the screen is small ', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('sm');

      expect(isMobile()).toBe(true);
    });

    it('returns true when the screen is extra-small ', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xs');

      expect(isMobile()).toBe(true);
    });

    it('returns false when the screen is larger than medium ', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('lg');

      expect(isMobile()).toBe(false);
    });
  });

  describe('getTopFrequentItems', () => {
    it('returns empty array if no items provided', () => {
      const result = getTopFrequentItems();

      expect(result.length).toBe(0);
    });

    it('returns correct amount of items for mobile', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');
      const result = getTopFrequentItems(unsortedFrequentItems);

      expect(result.length).toBe(FREQUENT_ITEMS.LIST_COUNT_MOBILE);
    });

    it('returns correct amount of items for desktop', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xl');
      const result = getTopFrequentItems(unsortedFrequentItems);

      expect(result.length).toBe(FREQUENT_ITEMS.LIST_COUNT_DESKTOP);
    });

    it('sorts frequent items in order of frequency and lastAccessedOn', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('xl');
      const result = getTopFrequentItems(unsortedFrequentItems);
      const expectedResult = sortedFrequentItems.slice(0, FREQUENT_ITEMS.LIST_COUNT_DESKTOP);

      expect(result).toEqual(expectedResult);
    });
  });

  describe('updateExistingFrequentItem', () => {
    let mockedProject;

    beforeEach(() => {
      mockedProject = {
        ...mockProject,
        frequency: 1,
        lastAccessedOn: 1497979281815,
      };
    });

    it('updates item if accessed over an hour ago', () => {
      const newTimestamp = Date.now() + HOUR_IN_MS + 1;
      const newItem = {
        ...mockedProject,
        lastAccessedOn: newTimestamp,
      };
      const result = updateExistingFrequentItem(mockedProject, newItem);

      expect(result.frequency).toBe(mockedProject.frequency + 1);
    });

    it('does not update item if accessed within the hour', () => {
      const newItem = {
        ...mockedProject,
        lastAccessedOn: mockedProject.lastAccessedOn + HOUR_IN_MS,
      };
      const result = updateExistingFrequentItem(mockedProject, newItem);

      expect(result.frequency).toBe(mockedProject.frequency);
    });
  });
});
