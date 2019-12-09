/* global List */
/* global ListAssignee */
/* global ListIssue */
/* global ListLabel */

import MockAdapter from 'axios-mock-adapter';
import _ from 'underscore';
import axios from '~/lib/utils/axios_utils';
import '~/boards/models/label';
import '~/boards/models/assignee';
import '~/boards/models/issue';
import '~/boards/models/list';
import boardsStore from '~/boards/stores/boards_store';
import { listObj, listObjDuplicate, boardsMockInterceptor } from './mock_data';

describe('List model', () => {
  let list;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);
    boardsStore.create();

    list = new List(listObj);
  });

  afterEach(() => {
    mock.restore();
  });

  it('gets issues when created', done => {
    setTimeout(() => {
      expect(list.issues.length).toBe(1);
      done();
    }, 0);
  });

  it('saves list and returns ID', done => {
    list = new List({
      title: 'test',
      label: {
        id: _.random(10000),
        title: 'test',
        color: 'red',
        text_color: 'white',
      },
    });
    list.save();

    setTimeout(() => {
      expect(list.id).toBe(listObj.id);
      expect(list.type).toBe('label');
      expect(list.position).toBe(0);
      expect(list.label.color).toBe('red');
      expect(list.label.textColor).toBe('white');
      done();
    }, 0);
  });

  it('destroys the list', done => {
    boardsStore.addList(listObj);
    list = boardsStore.findList('id', listObj.id);

    expect(boardsStore.state.lists.length).toBe(1);
    list.destroy();

    setTimeout(() => {
      expect(boardsStore.state.lists.length).toBe(0);
      done();
    }, 0);
  });

  it('gets issue from list', done => {
    setTimeout(() => {
      const issue = list.findIssue(1);

      expect(issue).toBeDefined();
      done();
    }, 0);
  });

  it('removes issue', done => {
    setTimeout(() => {
      const issue = list.findIssue(1);

      expect(list.issues.length).toBe(1);
      list.removeIssue(issue);

      expect(list.issues.length).toBe(0);
      done();
    }, 0);
  });

  it('sends service request to update issue label', () => {
    const listDup = new List(listObjDuplicate);
    const issue = new ListIssue({
      title: 'Testing',
      id: _.random(10000),
      iid: _.random(10000),
      confidential: false,
      labels: [list.label, listDup.label],
      assignees: [],
    });

    list.issues.push(issue);
    listDup.issues.push(issue);

    spyOn(boardsStore, 'moveIssue').and.callThrough();

    listDup.updateIssueLabel(issue, list);

    expect(boardsStore.moveIssue).toHaveBeenCalledWith(
      issue.id,
      list.id,
      listDup.id,
      undefined,
      undefined,
    );
  });

  describe('page number', () => {
    beforeEach(() => {
      spyOn(list, 'getIssues');
    });

    it('increase page number if current issue count is more than the page size', () => {
      for (let i = 0; i < 30; i += 1) {
        list.issues.push(
          new ListIssue({
            title: 'Testing',
            id: _.random(10000) + i,
            iid: _.random(10000) + i,
            confidential: false,
            labels: [list.label],
            assignees: [],
          }),
        );
      }
      list.issuesSize = 50;

      expect(list.issues.length).toBe(30);

      list.nextPage();

      expect(list.page).toBe(2);
      expect(list.getIssues).toHaveBeenCalled();
    });

    it('does not increase page number if issue count is less than the page size', () => {
      list.issues.push(
        new ListIssue({
          title: 'Testing',
          id: _.random(10000),
          confidential: false,
          labels: [list.label],
          assignees: [],
        }),
      );
      list.issuesSize = 2;

      list.nextPage();

      expect(list.page).toBe(1);
      expect(list.getIssues).toHaveBeenCalled();
    });
  });

  describe('newIssue', () => {
    beforeEach(() => {
      spyOn(boardsStore, 'newIssue').and.returnValue(
        Promise.resolve({
          data: {
            id: 42,
            subscribed: false,
            assignable_labels_endpoint: '/issue/42/labels',
            toggle_subscription_endpoint: '/issue/42/subscriptions',
            issue_sidebar_endpoint: '/issue/42/sidebar_info',
          },
        }),
      );
    });

    it('adds new issue to top of list', done => {
      const user = new ListAssignee({
        id: 1,
        name: 'testing 123',
        username: 'test',
        avatar: 'test_image',
      });

      list.issues.push(
        new ListIssue({
          title: 'Testing',
          id: _.random(10000),
          confidential: false,
          labels: [new ListLabel(list.label)],
          assignees: [],
        }),
      );
      const dummyIssue = new ListIssue({
        title: 'new issue',
        id: _.random(10000),
        confidential: false,
        labels: [new ListLabel(list.label)],
        assignees: [user],
        subscribed: false,
      });

      list
        .newIssue(dummyIssue)
        .then(() => {
          expect(list.issues.length).toBe(2);
          expect(list.issues[0]).toBe(dummyIssue);
          expect(list.issues[0].subscribed).toBe(false);
          expect(list.issues[0].assignableLabelsEndpoint).toBe('/issue/42/labels');
          expect(list.issues[0].toggleSubscriptionEndpoint).toBe('/issue/42/subscriptions');
          expect(list.issues[0].sidebarInfoEndpoint).toBe('/issue/42/sidebar_info');
          expect(list.issues[0].labels).toBe(dummyIssue.labels);
          expect(list.issues[0].assignees).toBe(dummyIssue.assignees);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
