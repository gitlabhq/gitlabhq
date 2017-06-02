/* global boardsMockInterceptor */
/* global BoardService */
/* global List */
/* global listObj */

import Vue from 'vue';
import boardNewIssue from '~/boards/components/board_new_issue';

import '~/boards/models/list';
import './mock_data';

describe('Issue boards new issue form', () => {
  let vm;
  let list;
  const promiseReturn = {
    json() {
      return {
        iid: 100,
      };
    },
  };
  const submitIssue = () => {
    vm.$el.querySelector('.btn-success').click();
  };

  beforeEach((done) => {
    const BoardNewIssueComp = Vue.extend(boardNewIssue);

    Vue.http.interceptors.push(boardsMockInterceptor);
    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();
    gl.IssueBoardsApp = new Vue();

    setTimeout(() => {
      list = new List(listObj);

      spyOn(gl.boardService, 'newIssue').and.callFake(() => new Promise((resolve, reject) => {
        if (vm.title === 'error') {
          reject();
        } else {
          resolve(promiseReturn);
        }
      }));

      vm = new BoardNewIssueComp({
        propsData: {
          list,
        },
      }).$mount();

      done();
    }, 0);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
  });

  it('disables submit button if title is empty', () => {
    expect(vm.$el.querySelector('.btn-success').disabled).toBe(true);
  });

  it('enables submit button if title is not empty', (done) => {
    vm.title = 'Testing Title';

    setTimeout(() => {
      expect(vm.$el.querySelector('.form-control').value).toBe('Testing Title');
      expect(vm.$el.querySelector('.btn-success').disabled).not.toBe(true);

      done();
    }, 0);
  });

  it('clears title after clicking cancel', (done) => {
    vm.$el.querySelector('.btn-default').click();

    setTimeout(() => {
      expect(vm.title).toBe('');
      done();
    }, 0);
  });

  it('does not create new issue if title is empty', (done) => {
    submitIssue();

    setTimeout(() => {
      expect(gl.boardService.newIssue).not.toHaveBeenCalled();
      done();
    }, 0);
  });

  describe('submit success', () => {
    it('creates new issue', (done) => {
      vm.title = 'submit title';

      setTimeout(() => {
        submitIssue();

        expect(gl.boardService.newIssue).toHaveBeenCalled();
        done();
      }, 0);
    });

    it('enables button after submit', (done) => {
      vm.title = 'submit issue';

      setTimeout(() => {
        submitIssue();

        expect(vm.$el.querySelector('.btn-success').disbled).not.toBe(true);
        done();
      }, 0);
    });

    it('clears title after submit', (done) => {
      vm.title = 'submit issue';

      setTimeout(() => {
        submitIssue();

        expect(vm.title).toBe('');
        done();
      }, 0);
    });

    it('adds new issue to list after submit', (done) => {
      vm.title = 'submit issue';

      setTimeout(() => {
        submitIssue();

        expect(list.issues.length).toBe(2);
        expect(list.issues[1].title).toBe('submit issue');
        expect(list.issues[1].subscribed).toBe(true);
        done();
      }, 0);
    });

    it('sets detail issue after submit', (done) => {
      vm.title = 'submit issue';

      setTimeout(() => {
        submitIssue();

        expect(gl.issueBoards.BoardsStore.detail.issue.title).toBe('submit issue');
        done();
      });
    });

    it('sets detail list after submit', (done) => {
      vm.title = 'submit issue';

      setTimeout(() => {
        submitIssue();

        expect(gl.issueBoards.BoardsStore.detail.list.id).toBe(list.id);
        done();
      }, 0);
    });
  });

  describe('submit error', () => {
    it('removes issue', (done) => {
      vm.title = 'error';

      setTimeout(() => {
        submitIssue();

        setTimeout(() => {
          expect(list.issues.length).toBe(1);
          done();
        }, 500);
      }, 0);
    });

    it('shows error', (done) => {
      vm.title = 'error';
      submitIssue();

      setTimeout(() => {
        submitIssue();

        setTimeout(() => {
          expect(vm.error).toBe(true);
          done();
        }, 500);
      }, 0);
    });
  });
});
