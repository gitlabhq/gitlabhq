/* global List */
/* global ListIssue */

import MockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import Sortable from 'sortablejs';
import BoardList from '~/boards/components/board_list.vue';

import '~/boards/models/issue';
import '~/boards/models/list';
import { listObj, boardsMockInterceptor } from './mock_data';
import store from '~/boards/stores';
import boardsStore from '~/boards/stores/boards_store';

window.Sortable = Sortable;

export default function createComponent({
  done,
  listIssueProps = {},
  componentProps = {},
  listProps = {},
}) {
  const el = document.createElement('div');

  document.body.appendChild(el);
  const mock = new MockAdapter(axios);
  mock.onAny().reply(boardsMockInterceptor);
  boardsStore.create();

  const BoardListComp = Vue.extend(BoardList);
  const list = new List({ ...listObj, ...listProps });
  const issue = new ListIssue({
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [],
    assignees: [],
    ...listIssueProps,
  });
  if (!Object.prototype.hasOwnProperty.call(listProps, 'issuesSize')) {
    list.issuesSize = 1;
  }
  list.issues.push(issue);

  const component = new BoardListComp({
    el,
    store,
    propsData: {
      disabled: false,
      list,
      issues: list.issues,
      loading: false,
      issueLinkBase: '/issues',
      rootPath: '/',
      ...componentProps,
    },
  }).$mount();

  Vue.nextTick(() => {
    done();
  });

  return { component, mock };
}
