import {
  getReferencePieces,
  assembleNecessaryIssuableReference,
  assembleFullIssuableReference,
} from '~/lib/utils/issuable_reference_utils';

describe('issuable_reference_utils', () => {
  describe('getReferencePieces', () => {
    it('should work with only issue number reference', () => {
      expect(getReferencePieces('#111', 'foo', 'bar')).toEqual({
        namespace: 'foo',
        project: 'bar',
        issue: '111',
      });
    });
    it('should work with project and issue number reference', () => {
      expect(getReferencePieces('qux#111', 'foo', 'bar')).toEqual({
        namespace: 'foo',
        project: 'qux',
        issue: '111',
      });
    });
    it('should work with full reference', () => {
      expect(getReferencePieces('foo/garply#111', 'foo', 'bar')).toEqual({
        namespace: 'foo',
        project: 'garply',
        issue: '111',
      });
    });
    it('should work with sub-groups', () => {
      expect(getReferencePieces('some/with/sub/groups/other#111', 'foo', 'bar')).toEqual({
        namespace: 'some/with/sub/groups',
        project: 'other',
        issue: '111',
      });
    });
    it('does not mangle other group references', () => {
      expect(getReferencePieces('some/other#111', 'foo', 'bar')).toEqual({
        namespace: 'some',
        project: 'other',
        issue: '111',
      });
    });
    it('does not mangle other group even with partial match', () => {
      expect(getReferencePieces('bar/baz/fido#111', 'foo/bar/baz', 'garply')).toEqual({
        namespace: 'bar/baz',
        project: 'fido',
        issue: '111',
      });
    });
  });

  describe('assembleNecessaryIssuableReference', () => {
    it('should work with only issue number reference', () => {
      expect(assembleNecessaryIssuableReference('#111', 'foo', 'bar')).toEqual('#111');
    });
    it('should work with project and issue number reference', () => {
      expect(assembleNecessaryIssuableReference('qux#111', 'foo', 'bar')).toEqual('qux#111');
    });
    it('should work with full reference to current project', () => {
      expect(assembleNecessaryIssuableReference('foo/garply#111', 'foo', 'bar')).toEqual('garply#111');
    });
    it('should work with sub-groups', () => {
      expect(assembleNecessaryIssuableReference('some/with/sub/groups/other#111', 'foo', 'bar')).toEqual('some/with/sub/groups/other#111');
    });
    it('does not mangle other group references', () => {
      expect(assembleNecessaryIssuableReference('some/other#111', 'foo', 'bar')).toEqual('some/other#111');
    });
    it('does not mangle other group even with partial match', () => {
      expect(assembleNecessaryIssuableReference('bar/baz/fido#111', 'foo/bar/baz', 'garply')).toEqual('bar/baz/fido#111');
    });
  });

  describe('assembleFullIssuableReference', () => {
    it('should work with only issue number reference', () => {
      expect(assembleFullIssuableReference('#111', 'foo', 'bar')).toEqual('foo/bar#111');
    });
    it('should work with project and issue number reference', () => {
      expect(assembleFullIssuableReference('qux#111', 'foo', 'bar')).toEqual('foo/qux#111');
    });
    it('should work with full reference', () => {
      expect(assembleFullIssuableReference('foo/garply#111', 'foo', 'bar')).toEqual('foo/garply#111');
    });
    it('should work with sub-groups', () => {
      expect(assembleFullIssuableReference('some/with/sub/groups/other#111', 'foo', 'bar')).toEqual('some/with/sub/groups/other#111');
    });
    it('does not mangle other group references', () => {
      expect(assembleFullIssuableReference('some/other#111', 'foo', 'bar')).toEqual('some/other#111');
    });
    it('does not mangle other group even with partial match', () => {
      expect(assembleFullIssuableReference('bar/baz/fido#111', 'foo/bar/baz', 'garply')).toEqual('bar/baz/fido#111');
    });
  });
});
