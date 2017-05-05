import {
  getReferencePieces,
  assembleDisplayIssuableReference,
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

  describe('assembleDisplayIssuableReference', () => {
    it('should work with only issue number reference', () => {
      expect(assembleDisplayIssuableReference({ iid: 111 }, 'foo', 'bar')).toEqual('#111');
    });
    it('should work with project and issue number reference', () => {
      expect(assembleDisplayIssuableReference({ project_path: 'qux', iid: 111 }, 'foo', 'bar')).toEqual('qux#111');
    });
    it('should work with full reference to current project', () => {
      expect(assembleDisplayIssuableReference({ namespace_full_path: 'foo', project_path: 'garply', iid: 111 }, 'foo', 'bar')).toEqual('garply#111');
    });
    it('should work with sub-groups', () => {
      expect(assembleDisplayIssuableReference({ namespace_full_path: 'some/with/sub/groups', project_path: 'other', iid: 111 }, 'foo', 'bar')).toEqual('some/with/sub/groups/other#111');
    });
    it('does not mangle other group references', () => {
      expect(assembleDisplayIssuableReference({ namespace_full_path: 'some', project_path: 'other', iid: 111 }, 'foo', 'bar')).toEqual('some/other#111');
    });
    it('does not mangle other group even with partial match', () => {
      expect(assembleDisplayIssuableReference({ namespace_full_path: 'bar/baz', project_path: 'fido', iid: 111 }, 'foo/bar/baz', 'garply')).toEqual('bar/baz/fido#111');
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
