import Vue from 'vue';
import terminalComp from '~/environments/components/environment_terminal_button.vue';

describe('Stop Component', () => {
  let component;
  const terminalPath = '/path';

  const mountWithProps = props => {
    const TerminalComponent = Vue.extend(terminalComp);
    component = new TerminalComponent({
      propsData: props,
    }).$mount();
  };

  beforeEach(() => {
    mountWithProps({ terminalPath });
  });

  describe('computed', () => {
    it('title', () => {
      expect(component.title).toEqual('Terminal');
    });
  });

  it('should render a link to open a web terminal with the provided path', () => {
    expect(component.$el.tagName).toEqual('A');
    expect(component.$el.getAttribute('data-original-title')).toEqual('Terminal');
    expect(component.$el.getAttribute('aria-label')).toEqual('Terminal');
    expect(component.$el.getAttribute('href')).toEqual(terminalPath);
  });

  it('should render a non-disabled button', () => {
    expect(component.$el.classList).not.toContain('disabled');
  });
});
