import * as CommitMergeRequests from '~/commit_merge_requests';

describe('CommitMergeRequests', () => {
  describe('createContent', () => {
    it('should return created content', () => {
      const content1 = CommitMergeRequests.createContent([{ iid: 1, path: '/path1', title: 'foo' }, { iid: 2, path: '/path2', title: 'baz' }])[0];
      expect(content1.tagName).toEqual('SPAN');
      expect(content1.childElementCount).toEqual(4);

      const content2 = CommitMergeRequests.createContent([])[0];
      expect(content2.tagName).toEqual('SPAN');
      expect(content2.childElementCount).toEqual(0);
      expect(content2.innerText).toEqual('No related merge requests found');
    });
  });

  describe('getHeaderText', () => {
    it('should return header text', () => {
      expect(CommitMergeRequests.getHeaderText(0, 1)).toEqual('1 merge request');
      expect(CommitMergeRequests.getHeaderText(0, 2)).toEqual('2 merge requests');
      expect(CommitMergeRequests.getHeaderText(1, 1)).toEqual(',');
      expect(CommitMergeRequests.getHeaderText(1, 2)).toEqual(',');
    });
  });

  describe('createHeader', () => {
    it('should return created header', () => {
      const header = CommitMergeRequests.createHeader(0, 1)[0];
      expect(header.tagName).toEqual('SPAN');
      expect(header.innerText).toEqual('1 merge request');
    });
  });

  describe('createItem', () => {
    it('should return created item', () => {
      const item = CommitMergeRequests.createItem({ iid: 1, path: '/path', title: 'foo' })[0];
      expect(item.tagName).toEqual('SPAN');
      expect(item.childElementCount).toEqual(2);
      expect(item.children[0].tagName).toEqual('A');
      expect(item.children[1].tagName).toEqual('SPAN');
    });
  });

  describe('createLink', () => {
    it('should return created link', () => {
      const link = CommitMergeRequests.createLink({ iid: 1, path: '/path', title: 'foo' })[0];
      expect(link.tagName).toEqual('A');
      expect(link.href).toMatch(/\/path$/);
      expect(link.innerText).toEqual('!1');
    });
  });

  describe('createTitle', () => {
    it('should return created title', () => {
      const title = CommitMergeRequests.createTitle({ iid: 1, path: '/path', title: 'foo' })[0];
      expect(title.tagName).toEqual('SPAN');
      expect(title.innerText).toEqual('foo');
    });
  });
});
