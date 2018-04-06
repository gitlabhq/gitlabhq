import Vue from 'vue';
import '~/boards/components/issue_card_inner';
import ListIssue from '~/boards/models/issue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { listObj } from './mock_data';

describe('Issue card component', () => {
  let vm;
  const Component = Vue.extend(gl.issueBoards.IssueCardInner);
  const list = listObj;
  const issue = new ListIssue({
    title: 'Testing',
    id: 1,
    iid: 1,
    confidential: false,
    labels: [list.label],
    assignees: [],
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('does not render issue weight if none specified', () => {
    vm = mountComponent(Component, {
      list,
      issue,
      issueLinkBase: '/test',
      rootPath: '/',
      groupId: null,
    });

    expect(
      vm.$el.querySelector('.card-weight'),
    ).toBeNull();
  });

  it('renders issue weight if specified', () => {
    vm = mountComponent(Component, {
      list,
      issue: {
        ...issue,
        weight: 2,
      },
      issueLinkBase: '/test',
      rootPath: '/',
      groupId: null,
    });
    const el = vm.$el.querySelector('.card-weight');

    expect(el).not.toBeNull();
    expect(el.textContent.trim()).toBe('2');
  });
});
