import { computeDiff } from '~/ide/lib/diff/diff';

describe('Multi-file editor library diff calculator', () => {
  describe('computeDiff', () => {
    it('returns empty array if no changes', () => {
      const diff = computeDiff('123', '123');

      expect(diff).toEqual([]);
    });

    describe('modified', () => {
      it('', () => {
        const diff = computeDiff('123', '1234')[0];

        expect(diff.added).toBeTruthy();
        expect(diff.modified).toBeTruthy();
        expect(diff.removed).toBeUndefined();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n1234\n123')[0];

        expect(diff.added).toBeTruthy();
        expect(diff.modified).toBeTruthy();
        expect(diff.removed).toBeUndefined();
        expect(diff.lineNumber).toBe(2);
      });
    });

    describe('added', () => {
      it('', () => {
        const diff = computeDiff('123', '123\n123')[0];

        expect(diff.added).toBeTruthy();
        expect(diff.modified).toBeUndefined();
        expect(diff.removed).toBeUndefined();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n123\n1234\n123')[0];

        expect(diff.added).toBeTruthy();
        expect(diff.modified).toBeUndefined();
        expect(diff.removed).toBeUndefined();
        expect(diff.lineNumber).toBe(3);
      });
    });

    describe('removed', () => {
      it('', () => {
        const diff = computeDiff('123', '')[0];

        expect(diff.added).toBeUndefined();
        expect(diff.modified).toBeUndefined();
        expect(diff.removed).toBeTruthy();
      });

      it('', () => {
        const diff = computeDiff('123\n123\n123', '123\n123')[0];

        expect(diff.added).toBeUndefined();
        expect(diff.modified).toBeTruthy();
        expect(diff.removed).toBeTruthy();
        expect(diff.lineNumber).toBe(2);
      });
    });

    it('includes line number of change', () => {
      const diff = computeDiff('123', '')[0];

      expect(diff.lineNumber).toBe(1);
    });

    it('includes end line number of change', () => {
      const diff = computeDiff('123', '')[0];

      expect(diff.endLineNumber).toBe(1);
    });
  });
});
