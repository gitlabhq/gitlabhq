import _ from 'underscore';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { trimText } from 'spec/helpers/vue_component_helper';

const localVue = createLocalVue();

describe('ProjectListItem component', () => {
  let wrapper;
  let vm;
  loadJSONFixtures('projects.json');
  const project = getJSONFixture('projects.json')[0];

  beforeEach(() => {
    wrapper = shallowMount(localVue.extend(ProjectListItem), {
      propsData: {
        project,
        selected: false,
      },
      sync: false,
      localVue,
    });

    ({ vm } = wrapper);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('does not render a check mark icon if selected === false', () => {
    expect(vm.$el.querySelector('.js-selected-icon.js-unselected')).toBeTruthy();
  });

  it('renders a check mark icon if selected === true', done => {
    wrapper.setProps({ selected: true });

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.js-selected-icon.js-selected')).toBeTruthy();
      done();
    });
  });

  it(`emits a "clicked" event when clicked`, () => {
    spyOn(vm, '$emit');
    vm.onClick();

    expect(vm.$emit).toHaveBeenCalledWith('click');
  });

  it(`renders the project avatar`, () => {
    expect(vm.$el.querySelector('.js-project-avatar')).toBeTruthy();
  });

  it(`renders a simple namespace name with a trailing slash`, done => {
    project.name_with_namespace = 'a / b';
    wrapper.setProps({ project: _.clone(project) });

    vm.$nextTick(() => {
      const renderedNamespace = trimText(vm.$el.querySelector('.js-project-namespace').textContent);

      expect(renderedNamespace).toBe('a /');
      done();
    });
  });

  it(`renders a properly truncated namespace with a trailing slash`, done => {
    project.name_with_namespace = 'a / b / c / d / e / f';
    wrapper.setProps({ project: _.clone(project) });

    vm.$nextTick(() => {
      const renderedNamespace = trimText(vm.$el.querySelector('.js-project-namespace').textContent);

      expect(renderedNamespace).toBe('a / ... / e /');
      done();
    });
  });

  it(`renders the project name`, done => {
    project.name = 'my-test-project';
    wrapper.setProps({ project: _.clone(project) });

    vm.$nextTick(() => {
      const renderedName = trimText(vm.$el.querySelector('.js-project-name').innerHTML);

      expect(renderedName).toBe('my-test-project');
      done();
    });
  });

  it(`renders the project name with highlighting in the case of a search query match`, done => {
    project.name = 'my-test-project';
    wrapper.setProps({ project: _.clone(project), matcher: 'pro' });

    vm.$nextTick(() => {
      const renderedName = trimText(vm.$el.querySelector('.js-project-name').innerHTML);

      const expected = 'my-test-<b>p</b><b>r</b><b>o</b>ject';

      expect(renderedName).toBe(expected);
      done();
    });
  });
});
