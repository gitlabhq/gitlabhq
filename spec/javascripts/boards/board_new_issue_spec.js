/* global List */

import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import boardNewIssue from '~/boards/components/board_new_issue.vue';
import boardsStore from '~/boards/stores/boards_store';

import '~/boards/models/list';
import { listObj, boardsMockInterceptor } from './mock_data';

describe('Issue boards new issue form', () => {
  let vm;
  let list;
  let mock;
  let newIssueMock;
  const promiseReturn = {
    data: {
      iid: 100,
    },
  };

  const submitIssue = () => {
    const dummySubmitEvent = {
      preventDefault() {},
    };
    vm.$refs.submitButton = vm.$el.querySelector('.btn-success');
    return vm.submit(dummySubmitEvent);
  };

  beforeEach(done => {
    setFixtures('<div class="test-container"></div>');

    const BoardNewIssueComp = Vue.extend(boardNewIssue);

    mock = new MockAdapter(axios);
    mock.onAny().reply(boardsMockInterceptor);

    boardsStore.create();

    list = new List(listObj);

    newIssueMock = Promise.resolve(promiseReturn);
    spyOn(list, 'newIssue').and.callFake(() => newIssueMock);

    vm = new BoardNewIssueComp({
      propsData: {
        list,
      },
    }).$mount(document.querySelector('.test-container'));

    Vue.nextTick()
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    mock.restore();
  });

  it('calls submit if submit button is clicked', done => {
    spyOn(vm, 'submit').and.callFake(e => e.preventDefault());
    vm.title = 'Testing Title';

    Vue.nextTick()
      .then(() => {
        vm.$el.querySelector('.btn-success').click();

        expect(vm.submit.calls.count()).toBe(1);
      })
      .then(done)
      .catch(done.fail);
  });

  it('disables submit button if title is empty', () => {
    expect(vm.$el.querySelector('.btn-success').disabled).toBe(true);
  });

  it('enables submit button if title is not empty', done => {
    vm.title = 'Testing Title';

    Vue.nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.form-control').value).toBe('Testing Title');
        expect(vm.$el.querySelector('.btn-success').disabled).not.toBe(true);
      })
      .then(done)
      .catch(done.fail);
  });

  it('clears title after clicking cancel', done => {
    vm.$el.querySelector('.btn-default').click();

    Vue.nextTick()
      .then(() => {
        expect(vm.title).toBe('');
      })
      .then(done)
      .catch(done.fail);
  });

  it('does not create new issue if title is empty', done => {
    submitIssue()
      .then(() => {
        expect(list.newIssue).not.toHaveBeenCalled();
      })
      .then(done)
      .catch(done.fail);
  });

  describe('submit success', () => {
    it('creates new issue', done => {
      vm.title = 'submit title';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(list.newIssue).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });

    it('enables button after submit', done => {
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.$el.querySelector('.btn-success').disabled).toBe(false);
        })
        .then(done)
        .catch(done.fail);
    });

    it('clears title after submit', done => {
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.title).toBe('');
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets detail issue after submit', done => {
      expect(boardsStore.detail.issue.title).toBe(undefined);
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.issue.title).toBe('submit issue');
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets detail list after submit', done => {
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.id).toBe(list.id);
        })
        .then(done)
        .catch(done.fail);
    });

    it('sets detail weight after submit', done => {
      boardsStore.weightFeatureAvailable = true;
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.weight).toBe(list.weight);
        })
        .then(done)
        .catch(done.fail);
    });

    it('does not set detail weight after submit', done => {
      boardsStore.weightFeatureAvailable = false;
      vm.title = 'submit issue';

      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(boardsStore.detail.list.weight).toBe(list.weight);
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('submit error', () => {
    beforeEach(() => {
      newIssueMock = Promise.reject(new Error('My hovercraft is full of eels!'));
      vm.title = 'error';
    });

    it('removes issue', done => {
      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(list.issues.length).toBe(1);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows error', done => {
      Vue.nextTick()
        .then(submitIssue)
        .then(() => {
          expect(vm.error).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
