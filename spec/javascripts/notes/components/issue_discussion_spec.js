import Vue from 'vue';
import store from '~/notes/stores';
import issueDiscussion from '~/notes/components/issue_discussion.vue';
import { issueDataMock, discussionMock } from '../mock_data';

describe('issue_discussion component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(issueDiscussion);

    store.dispatch('setIssueData', issueDataMock);

    vm = new Component({
      store,
      propsData: {
        note: discussionMock,
      },
    }).$mount();
  });

  it('should render user avatar', () => {
    console.log('vm', vm.$el);

  });

  it('should render discussion header', () => {

  });

  describe('updated note', () => {
    it('should show information about update', () => {

    });
  });

  describe('with open discussion', () => {
    it('should render system note', () => {

    });

    it('should render placeholder note', () => {

    });

    it('should render regular note', () => {

    });

    describe('actions', () => {
      it('should render reply button', () => {

      });

      it('should toggle reply form', () => {

      });

      it('should render signout widget when user is logged out', () => {

      });
    });
  });
});
