import Vue from 'vue';
import eventHub from '~/boards/eventhub';
import createComponent from './board_list_common_spec';

describe('Board list component', () => {
  let mock;
  let component;

  beforeEach(done => {
    ({ mock, component } = createComponent({ done }));
  });

  afterEach(() => {
    mock.restore();
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

    for (let i = 1; i < 20; i += 1) {
      const issue = Object.assign({}, component.list.issues[0]);
      issue.id += i;
      component.list.issues.push(issue);
    }

    Vue.nextTick(() => {
      component.$refs.list.scrollTop = 20000;

      setTimeout(() => {
        expect(component.list.nextPage).toHaveBeenCalled();

        done();
      });
    });
  });

  it('does not load issues if already loading', () => {
    component.list.nextPage = spyOn(component.list, 'nextPage').and.returnValue(
      new Promise(() => {}),
    );

    component.onScroll();
    component.onScroll();

    expect(component.list.nextPage).toHaveBeenCalledTimes(1);
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
