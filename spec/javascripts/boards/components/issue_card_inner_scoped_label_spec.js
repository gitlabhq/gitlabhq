import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import IssueCardInnerScopedLabel from '~/boards/components/issue_card_inner_scoped_label.vue';

describe('IssueCardInnerScopedLabel Component', () => {
  let vm;
  const Component = Vue.extend(IssueCardInnerScopedLabel);
  const props = {
    label: { title: 'Foo::Bar', description: 'Some Random Description' },
    labelStyle: { background: 'white', color: 'black' },
    scopedLabelsDocumentationLink: '/docs-link',
  };
  const createComponent = () => mountComponent(Component, { ...props });

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render label title', () => {
    expect(vm.$el.querySelector('.color-label').textContent.trim()).toEqual('Foo::Bar');
  });

  it('should render question mark symbol', () => {
    expect(vm.$el.querySelector('.fa-question-circle')).not.toBeNull();
  });

  it('should render label style provided', () => {
    const node = vm.$el.querySelector('.color-label');

    expect(node.style.background).toEqual(props.labelStyle.background);
    expect(node.style.color).toEqual(props.labelStyle.color);
  });

  it('should render the docs link', () => {
    expect(vm.$el.querySelector('a.scoped-label').href).toContain(
      props.scopedLabelsDocumentationLink,
    );
  });
});
