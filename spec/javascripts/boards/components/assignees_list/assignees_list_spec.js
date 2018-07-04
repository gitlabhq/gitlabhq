import '~/boards/stores/boards_store';

import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import AssigneesListComponent from 'ee/boards/components/assignees_list/';

import mountComponent from 'spec/helpers/vue_mount_component_helper';

import { mockAssigneesList } from '../../mock_data';

const createComponent = () => mountComponent(AssigneesListComponent, {
  listAssigneesPath: `${gl.TEST_HOST}/users.json`,
});

describe('AssigneesListComponent', () => {
  let vm;
  let mock;
  let statusCode;
  let response;

  gl.issueBoards.BoardsStore.create();
  gl.issueBoards.BoardsStore.state.assignees = [];

  beforeEach(() => {
    statusCode = 200;
    response = mockAssigneesList;

    mock = new MockAdapter(axios);

    document.body.innerHTML += '<div class="flash-container"></div>';
    mock.onGet(`${gl.TEST_HOST}/users.json`).reply(() => [statusCode, response]);
    vm = createComponent();
  });

  afterEach(() => {
    document.querySelector('.flash-container').remove();
    vm.$destroy();
    mock.restore();
  });

  describe('data', () => {
    it('returns default data props', () => {
      expect(vm.loading).toBe(true);
      expect(vm.store).toBe(gl.issueBoards.BoardsStore);
    });
  });

  describe('methods', () => {
    describe('loadAssignees', () => {
      it('calls axios.get and sets response to store.state.assignees', (done) => {
        mock.onGet(`${gl.TEST_HOST}/users.json`).reply(200, mockAssigneesList);
        gl.issueBoards.BoardsStore.state.assignees = [];

        vm.loadAssignees();
        setTimeout(() => {
          expect(vm.loading).toBe(false);
          expect(vm.store.state.assignees.length).toBe(mockAssigneesList.length);
          done();
        }, 0);
      });

      it('does not call axios.get when store.state.assignees is not empty', () => {
        spyOn(axios, 'get');
        gl.issueBoards.BoardsStore.state.assignees = mockAssigneesList;
        vm.loadAssignees();
        expect(axios.get).not.toHaveBeenCalled();
      });

      it('calls axios.get and shows Flash error when request fails', (done) => {
        mock.onGet(`${gl.TEST_HOST}/users.json`).reply(500, {});
        gl.issueBoards.BoardsStore.state.assignees = [];

        vm.loadAssignees();
        setTimeout(() => {
          expect(vm.loading).toBe(false);
          expect(document.querySelector('.flash-text').innerText.trim()).toBe('Something went wrong while fetching assignees list');
          done();
        }, 0);
      });
    });

    describe('handleItemClick', () => {
      it('creates new list in a store instance', () => {
        spyOn(vm.store, 'new');
        const assignee = mockAssigneesList[0];

        expect(vm.store.findList('title', assignee.name)).not.toBeDefined();
        vm.handleItemClick(assignee);
        expect(vm.store.new).toHaveBeenCalledWith(jasmine.any(Object));
      });
    });
  });
});
