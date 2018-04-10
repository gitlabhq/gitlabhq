import Vue from 'vue';
import DiffDiscussions from '~/diffs/components/diff_discussions.vue';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';

import discussionsMockData from '../mock_data/diff_discussions';

describe('DiffDiscussions', () => {
  let component;
  const getDiscussionsMockData = () => [Object.assign({}, discussionsMockData)];

  beforeEach(() => {
    component = createComponentWithStore(Vue.extend(DiffDiscussions), store, {
      notes: getDiscussionsMockData(),
    }).$mount(document.createElement('div'));
  });

  describe('template', () => {
    it('should have notes list', () => {
      const { $el } = component;

      expect($el.querySelectorAll('.discussion .note.timeline-entry').length).toEqual(5);
    });
  });
});
