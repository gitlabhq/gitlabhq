import { formatRelevantDigits, bytesToKiB } from '~/lib/utils/number_utils';

describe('Number Utils', () => {
  describe('formatRelevantDigits', () => {
    it('returns an empty string when the number is NaN', () => {
      expect(formatRelevantDigits('fail')).toBe('');
    });

    it('returns 4 decimals when there is 4 plus digits to the left', () => {
      const formattedNumber = formatRelevantDigits('1000.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];
      expect(rightFromDecimal.length).toBe(4);
      expect(leftFromDecimal.length).toBe(4);
    });

    it('returns 3 decimals when there is 1 digit to the left', () => {
      const formattedNumber = formatRelevantDigits('0.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];
      expect(rightFromDecimal.length).toBe(3);
      expect(leftFromDecimal.length).toBe(1);
    });

    it('returns 2 decimals when there is 2 digits to the left', () => {
      const formattedNumber = formatRelevantDigits('10.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];
      expect(rightFromDecimal.length).toBe(2);
      expect(leftFromDecimal.length).toBe(2);
    });

    it('returns 1 decimal when there is 3 digits to the left', () => {
      const formattedNumber = formatRelevantDigits('100.1234567');
      const rightFromDecimal = formattedNumber.split('.')[1];
      const leftFromDecimal = formattedNumber.split('.')[0];
      expect(rightFromDecimal.length).toBe(1);
      expect(leftFromDecimal.length).toBe(3);
    });
  });

  describe('bytesToKiB', () => {
    it('calculates KiB for the given bytes', () => {
      expect(bytesToKiB(1024)).toEqual(1);
      expect(bytesToKiB(1000)).toEqual(0.9765625);
    });
  });
});
