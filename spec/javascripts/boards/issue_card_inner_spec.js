/* global listObj */
/* global ListIssue */

import 'vue';
import '~/boards/components/issue_card_inner';
import '~/boards/models/issue';
import '~/boards/models/label';
import '~/boards/models/list';
import '~/boards/models/user';
import '~/boards/stores/boards_store';
import './mock_data';

const issueLinkBase = '/test';
const rootPath = '/';
const list = listObj;

const issue = new ListIssue({
  title: 'Testing',
  iid: 1,
  confidential: false,
  labels: [list.label],
});

const createComponent = propsData => new gl.issueBoards.IssueCardInner({
  el: document.createElement('div'),
  propsData,
});

describe('IssueCardInner', () => {
  describe('computed', () => {
    let vm;
    beforeEach(() => {
      vm = createComponent({
        list,
        issue,
        issueLinkBase,
        rootPath,
      });
    });

    describe('cardUrl', () => {
      it('should return the url of the card', () => {
        expect(vm.cardUrl).toEqual(`${issueLinkBase}/${issue.id}`);
      });
    });

    describe('assigneeUrl', () => {
      it('should return url of the assignee', () => {
        expect(vm.assigneeUrl).toEqual(`${rootPath}${issue.assignee.username}`);
      });
    });

    describe('assigneeUrlTitle', () => {
      it('should return url title of the assignee', () => {
        expect(vm.assigneeUrlTitle).toEqual(`Assigned to ${issue.assignee.name}`);
      });
    });

    describe('issueId', () => {
      it('should return formatted issue id', () => {
        expect(vm.issueId).toEqual(`#${issue.id}`);
      });
    });
  });
});
