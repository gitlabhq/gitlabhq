import Vue from 'vue';
import terminalComp from '~/environments/components/environment_terminal_button.vue';

describe('Stop Component', () => {
  let TerminalComponent;
  let component;
  const terminalPath = '/path';

  beforeEach(() => {
    TerminalComponent = Vue.extend(terminalComp);

    component = new TerminalComponent({
      propsData: {
        terminalPath,
      },
    }).$mount();
  });

  it('should render a link to open a web terminal with the provided path', () => {
    expect(component.$el.tagName).toEqual('A');
    expect(component.$el.getAttribute('title')).toEqual('Terminal');
    expect(component.$el.getAttribute('href')).toEqual(terminalPath);
  });
});
