import Vue from 'vue';
import unresolvedDiscussionsComponent from '~/vue_merge_request_widget/components/states/mr_widget_unresolved_discussions';

describe('MRWidgetUnresolvedDiscussions', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = unresolvedDiscussionsComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('template', () => {
    let el;
    let vm;
    const path = 'foo/bar';

    beforeEach(() => {
      const Component = Vue.extend(unresolvedDiscussionsComponent);
      const mr = {
        createIssueToResolveDiscussionsPath: path,
      };
      vm = new Component({
        el: document.createElement('div'),
        propsData: { mr },
      });
      el = vm.$el;
    });

    it('should have correct elements', () => {
      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain('There are unresolved discussions. Please resolve these discussions');
      expect(el.innerText).toContain('Create an issue to resolve them later');
      expect(el.querySelector('.js-create-issue').getAttribute('href')).toEqual(path);
    });

    it('should not show create issue button if user cannot create issue', (done) => {
      vm.mr.createIssueToResolveDiscussionsPath = '';

      Vue.nextTick(() => {
        expect(el.querySelector('.js-create-issue')).toEqual(null);
        done();
      });
    });
  });
});
