import Vue from 'vue';
import UnresolvedDiscussions from '~/vue_merge_request_widget/components/states/unresolved_discussions.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('UnresolvedDiscussions', () => {
  const Component = Vue.extend(UnresolvedDiscussions);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with discussions path', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { mr: {
        createIssueToResolveDiscussionsPath: gl.TEST_HOST,
      } });
    });

    it('should have correct elements', () => {
      expect(vm.$el.innerText).toContain('There are unresolved discussions. Please resolve these discussions');
      expect(vm.$el.innerText).toContain('Create an issue to resolve them later');
      expect(vm.$el.querySelector('.js-create-issue').getAttribute('href')).toEqual(gl.TEST_HOST);
    });
  });

  describe('without discussions path', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { mr: {} });
    });

    it('should not show create issue link if user cannot create issue', () => {
      expect(vm.$el.innerText).toContain('There are unresolved discussions. Please resolve these discussions');
      expect(vm.$el.querySelector('.js-create-issue')).toEqual(null);
    });
  });
});
