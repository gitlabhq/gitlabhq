import Vue from 'vue';
import relatedLinksComponent from '~/vue_merge_request_widget/components/mr_widget_related_links.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('MRWidgetRelatedLinks', () => {
  let vm;

  const createComponent = (data) => {
    const Component = Vue.extend(relatedLinksComponent);

    return mountComponent(Component, data);
  };

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('closesText', () => {
      it('returns Closes text for open merge request', () => {
        vm = createComponent({ state: 'open', relatedLinks: {} });
        expect(vm.closesText).toEqual('Closes');
      });

      it('returns correct text for closed merge request', () => {
        vm = createComponent({ state: 'closed', relatedLinks: {} });
        expect(vm.closesText).toEqual('Did not close');
      });

      it('returns correct tense for merged request', () => {
        vm = createComponent({ state: 'merged', relatedLinks: {} });
        expect(vm.closesText).toEqual('Closed');
      });
    });
  });

  it('should have only have closing issues text', () => {
    vm = createComponent({
      relatedLinks: {
        closing: '<a href="#">#23</a> and <a>#42</a>',
      },
    });
    const content = vm.$el.textContent.replace(/\n(\s)+/g, ' ').trim();

    expect(content).toContain('Closes #23 and #42');
    expect(content).not.toContain('Mentions');
  });

  it('should have only have mentioned issues text', () => {
    vm = createComponent({
      relatedLinks: {
        mentioned: '<a href="#">#7</a>',
      },
    });

    expect(vm.$el.innerText).toContain('Mentions #7');
    expect(vm.$el.innerText).not.toContain('Closes');
  });

  it('should have closing and mentioned issues at the same time', () => {
    vm = createComponent({
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
    vm = createComponent({
      relatedLinks: {
        assignToMe: '<a href="#">Assign yourself to these issues</a>',
      },
    });

    expect(vm.$el.innerText).toContain('Assign yourself to these issues');
  });
});
