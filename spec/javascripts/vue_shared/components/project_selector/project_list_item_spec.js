import { shallowMount, createLocalVue } from '@vue/test-utils';
import { trimText } from 'spec/helpers/text_helper';
import ProjectListItem from '~/vue_shared/components/project_selector/project_list_item.vue';

const localVue = createLocalVue();

describe('ProjectListItem component', () => {
  const Component = localVue.extend(ProjectListItem);
  let wrapper;
  let vm;
  let options;
  loadJSONFixtures('static/projects.json');
  const project = getJSONFixture('static/projects.json')[0];

  beforeEach(() => {
    options = {
      propsData: {
        project,
        selected: false,
      },
      sync: false,
      localVue,
    };
  });

  afterEach(() => {
    wrapper.vm.$destroy();
  });

  it('does not render a check mark icon if selected === false', () => {
    wrapper = shallowMount(Component, options);

    expect(wrapper.contains('.js-selected-icon.js-unselected')).toBe(true);
  });

  it('renders a check mark icon if selected === true', () => {
    options.propsData.selected = true;

    wrapper = shallowMount(Component, options);

    expect(wrapper.contains('.js-selected-icon.js-selected')).toBe(true);
  });

  it(`emits a "clicked" event when clicked`, () => {
    wrapper = shallowMount(Component, options);
    ({ vm } = wrapper);

    spyOn(vm, '$emit');
    wrapper.vm.onClick();

    expect(wrapper.vm.$emit).toHaveBeenCalledWith('click');
  });

  it(`renders the project avatar`, () => {
    wrapper = shallowMount(Component, options);

    expect(wrapper.contains('.js-project-avatar')).toBe(true);
  });

  it(`renders a simple namespace name with a trailing slash`, () => {
    options.propsData.project.name_with_namespace = 'a / b';

    wrapper = shallowMount(Component, options);
    const renderedNamespace = trimText(wrapper.find('.js-project-namespace').text());

    expect(renderedNamespace).toBe('a /');
  });

  it(`renders a properly truncated namespace with a trailing slash`, () => {
    options.propsData.project.name_with_namespace = 'a / b / c / d / e / f';

    wrapper = shallowMount(Component, options);
    const renderedNamespace = trimText(wrapper.find('.js-project-namespace').text());

    expect(renderedNamespace).toBe('a / ... / e /');
  });

  it(`renders the project name`, () => {
    options.propsData.project.name = 'my-test-project';

    wrapper = shallowMount(Component, options);
    const renderedName = trimText(wrapper.find('.js-project-name').text());

    expect(renderedName).toBe('my-test-project');
  });

  it(`renders the project name with highlighting in the case of a search query match`, () => {
    options.propsData.project.name = 'my-test-project';
    options.propsData.matcher = 'pro';

    wrapper = shallowMount(Component, options);
    const renderedName = trimText(wrapper.find('.js-project-name').html());
    const expected = 'my-test-<b>p</b><b>r</b><b>o</b>ject';

    expect(renderedName).toContain(expected);
  });

  it('prevents search query and project name XSS', () => {
    const alertSpy = spyOn(window, 'alert');
    options.propsData.project.name = "my-xss-pro<script>alert('XSS');</script>ject";
    options.propsData.matcher = "pro<script>alert('XSS');</script>";

    wrapper = shallowMount(Component, options);
    const renderedName = trimText(wrapper.find('.js-project-name').html());
    const expected = 'my-xss-project';

    expect(renderedName).toContain(expected);
    expect(alertSpy).not.toHaveBeenCalled();
  });
});
