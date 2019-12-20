/* global List */

import Vue from 'vue';
import eventHub from '~/boards/eventhub';
import createComponent from './board_list_common_spec';
import waitForPromises from '../helpers/wait_for_promises';

import '~/boards/models/list';

describe('Board list component', () => {
  let mock;
  let component;
  let getIssues;
  function generateIssues(compWrapper) {
    for (let i = 1; i < 20; i += 1) {
      const issue = Object.assign({}, compWrapper.list.issues[0]);
      issue.id += i;
      compWrapper.list.issues.push(issue);
    }
  }

  describe('When Expanded', () => {
    beforeEach(done => {
      getIssues = spyOn(List.prototype, 'getIssues').and.returnValue(new Promise(() => {}));
      ({ mock, component } = createComponent({ done }));
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    it('loads first page of issues', done => {
      waitForPromises()
        .then(() => {
          expect(getIssues).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders component', () => {
      expect(component.$el.classList.contains('board-list-component')).toBe(true);
    });

    it('renders loading icon', done => {
      component.loading = true;

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-list-loading')).not.toBeNull();

        done();
      });
    });

    it('renders issues', () => {
      expect(component.$el.querySelectorAll('.board-card').length).toBe(1);
    });

    it('sets data attribute with issue id', () => {
      expect(component.$el.querySelector('.board-card').getAttribute('data-issue-id')).toBe('1');
    });

    it('shows new issue form', done => {
      component.toggleForm();

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).not.toBeNull();

        expect(component.$el.querySelector('.is-smaller')).not.toBeNull();

        done();
      });
    });

    it('shows new issue form after eventhub event', done => {
      eventHub.$emit(`hide-issue-form-${component.list.id}`);

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).not.toBeNull();

        expect(component.$el.querySelector('.is-smaller')).not.toBeNull();

        done();
      });
    });

    it('does not show new issue form for closed list', done => {
      component.list.type = 'closed';
      component.toggleForm();

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-new-issue-form')).toBeNull();

        done();
      });
    });

    it('shows count list item', done => {
      component.showCount = true;

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-list-count')).not.toBeNull();

        expect(component.$el.querySelector('.board-list-count').textContent.trim()).toBe(
          'Showing all issues',
        );

        done();
      });
    });

    it('sets data attribute with invalid id', done => {
      component.showCount = true;

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-list-count').getAttribute('data-issue-id')).toBe(
          '-1',
        );

        done();
      });
    });

    it('shows how many more issues to load', done => {
      component.showCount = true;
      component.list.issuesSize = 20;

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-list-count').textContent.trim()).toBe(
          'Showing 1 of 20 issues',
        );

        done();
      });
    });

    it('loads more issues after scrolling', done => {
      spyOn(component.list, 'nextPage');
      component.$refs.list.style.height = '100px';
      component.$refs.list.style.overflow = 'scroll';
      generateIssues(component);

      Vue.nextTick(() => {
        component.$refs.list.scrollTop = 20000;

        waitForPromises()
          .then(() => {
            expect(component.list.nextPage).toHaveBeenCalled();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    it('does not load issues if already loading', done => {
      component.list.nextPage = spyOn(component.list, 'nextPage').and.returnValue(
        new Promise(() => {}),
      );

      component.onScroll();
      component.onScroll();

      waitForPromises()
        .then(() => {
          expect(component.list.nextPage).toHaveBeenCalledTimes(1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows loading more spinner', done => {
      component.showCount = true;
      component.list.loadingMore = true;

      Vue.nextTick(() => {
        expect(component.$el.querySelector('.board-list-count .gl-spinner')).not.toBeNull();

        done();
      });
    });
  });

  describe('When Collapsed', () => {
    beforeEach(done => {
      getIssues = spyOn(List.prototype, 'getIssues').and.returnValue(new Promise(() => {}));
      ({ mock, component } = createComponent({
        done,
        listProps: { type: 'closed', collapsed: true, issuesSize: 50 },
      }));
      generateIssues(component);
      component.scrollHeight = spyOn(component, 'scrollHeight').and.returnValue(0);
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    it('does not load all issues', done => {
      waitForPromises()
        .then(() => {
          // Initial getIssues from list constructor
          expect(getIssues).toHaveBeenCalledTimes(1);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('max issue count warning', () => {
    beforeEach(done => {
      ({ mock, component } = createComponent({
        done,
        listProps: { type: 'closed', collapsed: true, issuesSize: 50 },
      }));
    });

    afterEach(() => {
      mock.restore();
      component.$destroy();
    });

    describe('when issue count exceeds max issue count', () => {
      it('sets background to bg-danger-100', done => {
        component.list.issuesSize = 4;
        component.list.maxIssueCount = 3;

        Vue.nextTick(() => {
          expect(component.$el.querySelector('.bg-danger-100')).not.toBeNull();

          done();
        });
      });
    });

    describe('when list issue count does NOT exceed list max issue count', () => {
      it('does not sets background to bg-danger-100', done => {
        component.list.issuesSize = 2;
        component.list.maxIssueCount = 3;

        Vue.nextTick(() => {
          expect(component.$el.querySelector('.bg-danger-100')).toBeNull();

          done();
        });
      });
    });

    describe('when list max issue count is 0', () => {
      it('does not sets background to bg-danger-100', done => {
        component.list.maxIssueCount = 0;

        Vue.nextTick(() => {
          expect(component.$el.querySelector('.bg-danger-100')).toBeNull();

          done();
        });
      });
    });
  });
});
