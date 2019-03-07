import { shallowMount } from '@vue/test-utils';
import { shallowWrapperContainsSlotText } from './vue_test_utils_helper';

describe('Vue test utils helpers', () => {
  describe('shallowWrapperContainsSlotText', () => {
    const mockText = 'text';
    const mockSlot = `<div>${mockText}</div>`;
    let mockComponent;

    beforeEach(() => {
      mockComponent = shallowMount(
        {
          render(h) {
            h(`<div>mockedComponent</div>`);
          },
        },
        {
          slots: {
            default: mockText,
            namedSlot: mockSlot,
          },
        },
      );
    });

    it('finds text within shallowWrapper default slot', () => {
      expect(shallowWrapperContainsSlotText(mockComponent, 'default', mockText)).toBe(true);
    });

    it('finds text within shallowWrapper named slot', () => {
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', mockText)).toBe(true);
    });

    it('returns false when text is not present', () => {
      const searchText = 'absent';

      expect(shallowWrapperContainsSlotText(mockComponent, 'default', searchText)).toBe(false);
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', searchText)).toBe(false);
    });

    it('searches with case-sensitivity', () => {
      const searchText = mockText.toUpperCase();

      expect(shallowWrapperContainsSlotText(mockComponent, 'default', searchText)).toBe(false);
      expect(shallowWrapperContainsSlotText(mockComponent, 'namedSlot', searchText)).toBe(false);
    });
  });
});
