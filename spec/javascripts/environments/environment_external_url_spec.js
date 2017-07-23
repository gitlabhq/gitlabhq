import Vue from 'vue';
import externalUrlComp from '~/environments/components/environment_external_url.vue';

describe('External URL Component', () => {
  let ExternalUrlComponent;

  beforeEach(() => {
    ExternalUrlComponent = Vue.extend(externalUrlComp);
  });

  it('should link to the provided externalUrl prop', () => {
    const externalURL = 'https://gitlab.com';
    const component = new ExternalUrlComponent({
      propsData: {
        externalUrl: externalURL,
      },
    }).$mount();

    expect(component.$el.getAttribute('href')).toEqual(externalURL);
    expect(component.$el.querySelector('fa-external-link')).toBeDefined();
  });
});
