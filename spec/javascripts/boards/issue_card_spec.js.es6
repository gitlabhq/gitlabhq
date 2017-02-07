/* global Vue */
/* global ListUser */
/* global ListLabel */
/* global listObj */
/* global ListIssue */

require('~/boards/models/issue');
require('~/boards/models/label');
require('~/boards/models/list');
require('~/boards/models/user');
require('~/boards/stores/boards_store');
require('~/boards/components/issue_card_inner');
require('./mock_data');

describe('Issue card component', () => {
  const user = new ListUser({
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
      iid: 1,
      confidential: false,
      labels: [list.label],
    });

    component = new Vue({
      el: document.querySelector('.test-container'),
      data() {
        return {
          list,
          issue,
          issueLinkBase: '/test',
          rootPath: '/',
        };
      },
      components: {
        'issue-card': gl.issueBoards.IssueCardInner,
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
      component.$el.querySelector('.card-title').textContent,
    ).toContain(issue.title);
  });

  it('includes issue base in link', () => {
    expect(
      component.$el.querySelector('.card-title a').getAttribute('href'),
    ).toContain('/test');
  });

  it('includes issue title on link', () => {
    expect(
      component.$el.querySelector('.card-title a').getAttribute('title'),
    ).toBe(issue.title);
  });

  it('does not render confidential icon', () => {
    expect(
      component.$el.querySelector('.fa-eye-flash'),
    ).toBeNull();
  });

  it('renders confidential icon', (done) => {
    component.issue.confidential = true;

    setTimeout(() => {
      expect(
        component.$el.querySelector('.confidential-icon'),
      ).not.toBeNull();
      done();
    }, 0);
  });

  it('renders issue ID with #', () => {
    expect(
      component.$el.querySelector('.card-number').textContent,
    ).toContain(`#${issue.id}`);
  });

  describe('assignee', () => {
    it('does not render assignee', () => {
      expect(
        component.$el.querySelector('.card-assignee'),
      ).toBeNull();
    });

    describe('exists', () => {
      beforeEach((done) => {
        component.issue.assignee = user;

        setTimeout(() => {
          done();
        }, 0);
      });

      it('renders assignee', () => {
        expect(
          component.$el.querySelector('.card-assignee'),
        ).not.toBeNull();
      });

      it('sets title', () => {
        expect(
          component.$el.querySelector('.card-assignee').getAttribute('title'),
        ).toContain(`Assigned to ${user.name}`);
      });

      it('sets users path', () => {
        expect(
          component.$el.querySelector('.card-assignee').getAttribute('href'),
        ).toBe('/test');
      });

      it('renders avatar', () => {
        expect(
          component.$el.querySelector('.card-assignee img'),
        ).not.toBeNull();
      });
    });
  });

  describe('labels', () => {
    it('does not render any', () => {
      expect(
        component.$el.querySelector('.label'),
      ).toBeNull();
    });

    describe('exists', () => {
      beforeEach((done) => {
        component.issue.addLabel(label1);

        setTimeout(() => {
          done();
        }, 0);
      });

      it('does not render list label', () => {
        expect(
          component.$el.querySelectorAll('.label').length,
        ).toBe(1);
      });

      it('renders label', () => {
        expect(
          component.$el.querySelector('.label').textContent,
        ).toContain(label1.title);
      });

      it('sets label description as title', () => {
        expect(
          component.$el.querySelector('.label').getAttribute('title'),
        ).toContain(label1.description);
      });

      it('sets background color of button', () => {
        expect(
          component.$el.querySelector('.label').style.backgroundColor,
        ).toContain(label1.color);
      });
    });
  });
});
