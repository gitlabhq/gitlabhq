import { computeDiff } from '~/repo/lib/diff/diff';

describe('Multi-file editor library diff calculator', () => {
  describe('computeDiff', () => {
    it('returns empty array if no changes', () => {
      const diff = computeDiff('123', '123');

      expect(diff).toEqual([]);
    });

    describe('modified', () => {
      it('', () => {
        const diff = computeDiff('123', '1234');

        expect(diff[0].added).toBeTruthy();
        expect(diff[0].modified).toBeTruthy();
        expect(diff[0].removed).toBeUndefined();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n1234\n123');

        expect(diff[0].added).toBeTruthy();
        expect(diff[0].modified).toBeTruthy();
        expect(diff[0].removed).toBeUndefined();
        expect(diff[0].lineNumber).toBe(2);
      });
    });

    describe('added', () => {
      it('', () => {
        const diff = computeDiff('123', '123\n123');

        expect(diff[0].added).toBeTruthy();
        expect(diff[0].modified).toBeUndefined();
        expect(diff[0].removed).toBeUndefined();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n123\n1234\n123');

        expect(diff[0].added).toBeTruthy();
        expect(diff[0].modified).toBeUndefined();
        expect(diff[0].removed).toBeUndefined();
        expect(diff[0].lineNumber).toBe(3);
      });
    });

    describe('removed', () => {
      it('', () => {
        const diff = computeDiff('123', '');

        expect(diff[0].added).toBeUndefined();
        expect(diff[0].modified).toBeUndefined();
        expect(diff[0].removed).toBeTruthy();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n123');

        expect(diff[0].added).toBeUndefined();
        expect(diff[0].modified).toBeTruthy();
        expect(diff[0].removed).toBeTruthy();
        expect(diff[0].lineNumber).toBe(2);
      });
    });

    it('includes line number of change', () => {
      const diff = computeDiff('123', '');

      expect(diff[0].lineNumber).toBe(1);
    });

    it('includes end line number of change', () => {
      const diff = computeDiff('123', '');

      expect(diff[0].endLineNumber).toBe(1);
    });
  });
});
