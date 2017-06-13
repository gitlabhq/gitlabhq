import Vue from 'vue';
import MRWidgetRelatedLinks from '~/vue_merge_request_widget/components/mr_widget_related_links';

describe('MRWidgetRelatedLinks', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(MRWidgetRelatedLinks);
    vm = new Component({
      el: document.createElement('div'),
      propsData: {
        relatedLinks: {},
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('props', () => {
    it('should have props', () => {
      const { relatedLinks } = MRWidgetRelatedLinks.props;

      expect(relatedLinks).toBeDefined();
      expect(relatedLinks.type instanceof Object).toBeTruthy();
      expect(relatedLinks.required).toBeTruthy();
    });
  });

  describe('computed', () => {
    describe('hasLinks', () => {
      it('should return correct value when we have links reference', () => {
        vm.relatedLinks = {
          closing: '/foo',
          mentioned: '/foo',
          assignToMe: '/foo',
        };

        expect(vm.hasLinks).toBeTruthy();

        vm.relatedLinks.closing = null;
        expect(vm.hasLinks).toBeTruthy();

        vm.relatedLinks.mentioned = null;
        expect(vm.hasLinks).toBeTruthy();

        vm.relatedLinks.assignToMe = null;
        expect(vm.hasLinks).toBeFalsy();
      });
    });
  });

  describe('methods', () => {
    const relatedLinks = {
      closing: '<a href="#">#23</a> and <a>#42</a>',
      mentioned: '<a href="#">#7</a>',
    };

    beforeEach(() => {
      vm.relatedLinks = relatedLinks;
    });

    describe('hasMultipleIssues', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.hasMultipleIssues(relatedLinks.closing)).toBeTruthy();
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.hasMultipleIssues(relatedLinks.mentioned)).toBeFalsy();
      });
    });

    describe('issueLabel', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.issueLabel('closing')).toEqual('issues');
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.issueLabel('mentioned')).toEqual('issue');
      });
    });

    describe('verbLabel', () => {
      it('should return true if the given text has multiple issues', () => {
        expect(vm.verbLabel('closing')).toEqual('are');
      });

      it('should return false if the given text has one issue', () => {
        expect(vm.verbLabel('mentioned')).toEqual('is');
      });
    });
  });

  describe('template', () => {
    it('should have only have closing issues text', (done) => {
      vm.relatedLinks = {
        closing: '<a href="#">#23</a> and <a>#42</a>',
      };

      Vue.nextTick()
      .then(() => {
        const content = vm.$el.textContent.replace(/\n(\s)+/g, ' ').trim();

        expect(content).toContain('Closes issues #23 and #42');
        expect(content).not.toContain('mentioned');
      })
      .then(done)
      .catch(done.fail);
    });

    it('should have only have mentioned issues text', (done) => {
      vm.relatedLinks = {
        mentioned: '<a href="#">#7</a>',
      };

      Vue.nextTick()
      .then(() => {
        expect(vm.$el.innerText).toContain('issue #7');
        expect(vm.$el.innerText).toContain('is mentioned but will not be closed.');
        expect(vm.$el.innerText).not.toContain('Closes');
      })
      .then(done)
      .catch(done.fail);
    });

    it('should have closing and mentioned issues at the same time', (done) => {
      vm.relatedLinks = {
        closing: '<a href="#">#7</a>',
        mentioned: '<a href="#">#23</a> and <a>#42</a>',
      };

      Vue.nextTick()
      .then(() => {
        const content = vm.$el.textContent.replace(/\n(\s)+/g, ' ').trim();

        expect(content).toContain('Closes issue #7.');
        expect(content).toContain('issues #23 and #42');
        expect(content).toContain('are mentioned but will not be closed.');
      })
      .then(done)
      .catch(done.fail);
    });

    it('should have assing issues link', (done) => {
      vm.relatedLinks = {
        assignToMe: '<a href="#">Assign yourself to these issues</a>',
      };

      Vue.nextTick()
      .then(() => {
        expect(vm.$el.innerText).toContain('Assign yourself to these issues');
      })
      .then(done)
      .catch(done.fail);
    });
  });
});
