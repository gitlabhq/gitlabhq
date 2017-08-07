import Vue from 'vue';
import relatedLinksComponent from '~/vue_merge_request_widget/components/mr_widget_related_links';

const createComponent = (data) => {
  const Component = Vue.extend(relatedLinksComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: data,
  });
};

describe('MRWidgetRelatedLinks', () => {
  describe('props', () => {
    it('should have props', () => {
      const { relatedLinks } = relatedLinksComponent.props;

      expect(relatedLinks).toBeDefined();
      expect(relatedLinks.type instanceof Object).toBeTruthy();
      expect(relatedLinks.required).toBeTruthy();
    });
  });

  describe('computed', () => {
    describe('hasLinks', () => {
      it('should return correct value when we have links reference', () => {
        const data = {
          relatedLinks: {
            closing: '/foo',
            mentioned: '/foo',
            assignToMe: '/foo',
          },
        };
        const vm = createComponent(data);
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
    const data = {
      relatedLinks: {
        closing: '<a href="#">#23</a> and <a>#42</a>',
        mentioned: '<a href="#">#7</a>',
      },
    };
    const vm = createComponent(data);

    describe('closesText', () => {
      it('returns correct text for open merge request', () => {
        expect(vm.closesText('open')).toEqual('Closes');
      });

      it('returns correct text for closed merge request', () => {
        expect(vm.closesText('closed')).toEqual('Did not close');
      });

      it('returns correct tense for merged request', () => {
        expect(vm.closesText('merged')).toEqual('Closed');
      });
    });
  });

  describe('template', () => {
    it('should have only have closing issues text', () => {
      const vm = createComponent({
        relatedLinks: {
          closing: '<a href="#">#23</a> and <a>#42</a>',
        },
      });
      const content = vm.$el.textContent.replace(/\n(\s)+/g, ' ').trim();

      expect(content).toContain('Closes #23 and #42');
      expect(content).not.toContain('Mentions');
    });

    it('should have only have mentioned issues text', () => {
      const vm = createComponent({
        relatedLinks: {
          mentioned: '<a href="#">#7</a>',
        },
      });

      expect(vm.$el.innerText).toContain('Mentions #7');
      expect(vm.$el.innerText).not.toContain('Closes');
    });

    it('should have closing and mentioned issues at the same time', () => {
      const vm = createComponent({
        relatedLinks: {
          closing: '<a href="#">#7</a>',
          mentioned: '<a href="#">#23</a> and <a>#42</a>',
        },
      });
      const content = vm.$el.textContent.replace(/\n(\s)+/g, ' ').trim();

      expect(content).toContain('Closes #7');
      expect(content).toContain('Mentions #23 and #42');
    });

    it('should have assing issues link', () => {
      const vm = createComponent({
        relatedLinks: {
          assignToMe: '<a href="#">Assign yourself to these issues</a>',
        },
      });

      expect(vm.$el.innerText).toContain('Assign yourself to these issues');
    });
  });
});
