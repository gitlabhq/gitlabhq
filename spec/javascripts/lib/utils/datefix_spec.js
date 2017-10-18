import { pad, parsePikadayDate, pikadayToString } from '~/lib/utils/datefix';

describe('datefix', () => {
  describe('pad', () => {
    it('should add a 0 when length is smaller than 2', () => {
      expect(pad(2)).toEqual('02');
    });

    it('should not add a zero when lenght matches the default', () => {
      expect(pad(12)).toEqual('12');
    });

    it('should add a 0 when lenght is smaller than the provided', () => {
      expect(pad(12, 3)).toEqual('012');
    });
  });

  describe('parsePikadayDate', () => {
    it('should return a UTC date', () => {
      expect(parsePikadayDate('2020-01-29')).toEqual(new Date('2020-01-29'));
    });
  });

  describe('pikadayToString', () => {
    it('should format a UTC date into yyyy-mm-dd format', () => {
      expect(pikadayToString(new Date('2020-01-29'))).toEqual('2020-01-29');
    });
  });
});
