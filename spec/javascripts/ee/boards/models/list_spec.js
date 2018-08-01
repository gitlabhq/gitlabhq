import { listObj, mockBoardService } from 'spec/boards/mock_data';
import CeList from '~/boards/models/list';
import List from 'ee/boards/models/list';
import Issue from 'ee/boards/models/issue';

describe('List model', () => {
  let list;
  let issue;

  beforeEach(() => {
    gl.boardService = mockBoardService();

    list = new List(listObj);
    issue = new Issue({
      title: 'Testing',
      id: 2,
      iid: 2,
      labels: [],
      assignees: [],
      weight: 5,
    });
  });

  afterEach(() => {
    list = null;
    issue = null;
  });

  it('inits totalWeight', () => {
    expect(list.totalWeight).toBe(0);
  });

  describe('getIssues', () => {
    it('calls CE getIssues', (done) => {
      const ceGetIssues = spyOn(CeList.prototype, 'getIssues').and.returnValue(Promise.resolve({}));

      list.getIssues().then(() => {
        expect(ceGetIssues).toHaveBeenCalled();
        done();
      }).catch(done.fail);
    });

    it('sets total weight', (done) => {
      spyOn(CeList.prototype, 'getIssues').and.returnValue(Promise.resolve({
        total_weight: 11,
      }));

      list.getIssues().then(() => {
        expect(list.totalWeight).toBe(11);
        done();
      }).catch(done.fail);
    });
  });

  describe('addIssue', () => {
    it('updates totalWeight', () => {
      list.addIssue(issue);

      expect(list.totalWeight).toBe(5);
    });

    it('calls CE addIssue with all args', () => {
      const ceAddIssue = spyOn(CeList.prototype, 'addIssue');

      list.addIssue(issue, list, 2);

      expect(ceAddIssue).toHaveBeenCalledWith(issue, list, 2);
    });
  });

  describe('removeIssue', () => {
    beforeEach(() => {
      list.addIssue(issue);
    });

    it('updates totalWeight', () => {
      list.removeIssue(issue);

      expect(list.totalWeight).toBe(0);
    });

    it('calls CE removeIssue', () => {
      const ceRemoveIssue = spyOn(CeList.prototype, 'removeIssue');

      list.removeIssue(issue);

      expect(ceRemoveIssue).toHaveBeenCalledWith(issue);
    });
  });
});
