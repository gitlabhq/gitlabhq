/* global ListAssignee */
/* global ListLabel */
/* global ListIssue */

import Vue from 'vue';

import '~/vue_shared/models/label';
import '~/boards/models/issue';
import '~/boards/models/list';
import '~/boards/models/assignee';
import '~/boards/stores/boards_store';
import '~/boards/components/issue_card_inner';
import { listObj } from './mock_data';

describe('Issue card component', () => {
  const user = new ListAssignee({
    id: 1,
    name: 'testing 123',
    username: 'test',
    avatar: 'test_image',
  });
  const label1 = new ListLabel({
    id: 3,
    title: 'testing 123',
    color: 'blue',
    text_color: 'white',
    description: 'test',
  });
  let component;
  let issue;
  let list;

  beforeEach(() => {
    setFixtures('<div class="test-container"></div>');

    list = listObj;
    issue = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      reference_path: '#1',
      real_path: '/test/1',
    });

    component = new Vue({
      el: document.querySelector('.test-container'),
      components: {
        'issue-card': gl.issueBoards.IssueCardInner,
      },
      data() {
        return {
          list,
          issue,
          issueLinkBase: '/test',
          rootPath: '/',
        };
      },
      template: `
        <issue-card
          :issue="issue"
          :list="list"
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"></issue-card>
      `,
    });
  });

  it('renders issue title', () => {
    expect(
      component.$el.querySelector('.board-card-title').textContent,
    ).toContain(issue.title);
  });

  it('includes issue base in link', () => {
    expect(
      component.$el.querySelector('.board-card-title a').getAttribute('href'),
    ).toContain('/test');
  });

  it('includes issue title on link', () => {
    expect(
      component.$el.querySelector('.board-card-title a').getAttribute('title'),
    ).toBe(issue.title);
  });

  it('does not render confidential icon', () => {
    expect(
      component.$el.querySelector('.fa-eye-flash'),
    ).toBeNull();
  });

  it('renders confidential icon', (done) => {
    component.issue.confidential = true;

    Vue.nextTick(() => {
      expect(
        component.$el.querySelector('.confidential-icon'),
      ).not.toBeNull();
      done();
    });
  });

  it('renders issue ID with #', () => {
    expect(
      component.$el.querySelector('.board-card-number').textContent,
    ).toContain(`#${issue.id}`);
  });

  describe('assignee', () => {
    it('does not render assignee', () => {
      expect(
        component.$el.querySelector('.board-card-assignee .avatar'),
      ).toBeNull();
    });

    describe('exists', () => {
      beforeEach((done) => {
        component.issue.assignees = [user];

        Vue.nextTick(() => done());
      });

      it('renders assignee', () => {
        expect(
          component.$el.querySelector('.board-card-assignee .avatar'),
        ).not.toBeNull();
      });

      it('sets title', () => {
        expect(
          component.$el.querySelector('.board-card-assignee img').getAttribute('data-original-title'),
        ).toContain(`Assigned to ${user.name}`);
      });

      it('sets users path', () => {
        expect(
          component.$el.querySelector('.board-card-assignee a').getAttribute('href'),
        ).toBe('/test');
      });

      it('renders avatar', () => {
        expect(
          component.$el.querySelector('.board-card-assignee img'),
        ).not.toBeNull();
      });
    });

    describe('assignee default avatar', () => {
      beforeEach((done) => {
        component.issue.assignees = [new ListAssignee({
          id: 1,
          name: 'testing 123',
          username: 'test',
        }, 'default_avatar')];

        Vue.nextTick(done);
      });

      it('displays defaults avatar if users avatar is null', () => {
        expect(
          component.$el.querySelector('.board-card-assignee img'),
        ).not.toBeNull();
        expect(
          component.$el.querySelector('.board-card-assignee img').getAttribute('src'),
        ).toBe('default_avatar');
      });
    });
  });

  describe('multiple assignees', () => {
    beforeEach((done) => {
      component.issue.assignees = [
        user,
        new ListAssignee({
          id: 2,
          name: 'user2',
          username: 'user2',
          avatar: 'test_image',
        }),
        new ListAssignee({
          id: 3,
          name: 'user3',
          username: 'user3',
          avatar: 'test_image',
        }),
        new ListAssignee({
          id: 4,
          name: 'user4',
          username: 'user4',
          avatar: 'test_image',
        })];

      Vue.nextTick(() => done());
    });

    it('renders all four assignees', () => {
      expect(component.$el.querySelectorAll('.board-card-assignee .avatar').length).toEqual(4);
    });

    describe('more than four assignees', () => {
      beforeEach((done) => {
        component.issue.assignees.push(new ListAssignee({
          id: 5,
          name: 'user5',
          username: 'user5',
          avatar: 'test_image',
        }));

        Vue.nextTick(() => done());
      });

      it('renders more avatar counter', () => {
        expect(component.$el.querySelector('.board-card-assignee .avatar-counter').innerText).toEqual('+2');
      });

      it('renders three assignees', () => {
        expect(component.$el.querySelectorAll('.board-card-assignee .avatar').length).toEqual(3);
      });

      it('renders 99+ avatar counter', (done) => {
        for (let i = 5; i < 104; i += 1) {
          const u = new ListAssignee({
            id: i,
            name: 'name',
            username: 'username',
            avatar: 'test_image',
          });
          component.issue.assignees.push(u);
        }

        Vue.nextTick(() => {
          expect(component.$el.querySelector('.board-card-assignee .avatar-counter').innerText).toEqual('99+');
          done();
        });
      });
    });
  });

  describe('labels', () => {
    beforeEach((done) => {
      component.issue.addLabel(label1);

      Vue.nextTick(() => done());
    });

    it('renders list label', () => {
      expect(
        component.$el.querySelectorAll('.label').length,
      ).toBe(2);
    });

    it('renders label', () => {
      const nodes = [];
      component.$el.querySelectorAll('.label').forEach((label) => {
        nodes.push(label.title);
      });

      expect(
        nodes.includes(label1.description),
      ).toBe(true);
    });

    it('sets label description as title', () => {
      expect(
        component.$el.querySelector('.label').getAttribute('title'),
      ).toContain(label1.description);
    });

    it('sets background color of button', () => {
      const nodes = [];
      component.$el.querySelectorAll('.label').forEach((label) => {
        nodes.push(label.style.backgroundColor);
      });

      expect(
        nodes.includes(label1.color),
      ).toBe(true);
    });

    it('does not render label if label does not have an ID', (done) => {
      component.issue.addLabel(new ListLabel({
        title: 'closed',
      }));

      Vue.nextTick()
        .then(() => {
          expect(
            component.$el.querySelectorAll('.label').length,
          ).toBe(2);
          expect(
            component.$el.textContent,
          ).not.toContain('closed');

          done();
        })
        .catch(done.fail);
    });
  });
});
