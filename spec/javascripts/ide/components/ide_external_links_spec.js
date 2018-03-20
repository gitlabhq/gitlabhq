import Vue from 'vue';
import ideExternalLinks from '~/ide/components/ide_external_links.vue';
import createComponent from 'spec/helpers/vue_mount_component_helper';

describe('ide external links component', () => {
  let vm;
  let fakeReferrer;
  let Component;

  const fakeProjectUrl = '/project/';

  beforeEach(() => {
    Component = Vue.extend(ideExternalLinks);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('goBackUrl', () => {
    it('renders the Go Back link with the referrer when present', () => {
      fakeReferrer = '/example/README.md';
      spyOnProperty(document, 'referrer').and.returnValue(fakeReferrer);

      vm = createComponent(Component, {
        projectUrl: fakeProjectUrl,
      }).$mount();

      expect(vm.goBackUrl).toEqual(fakeReferrer);
    });

    it('renders the Go Back link with the project url when referrer is not present', () => {
      fakeReferrer = '';
      spyOnProperty(document, 'referrer').and.returnValue(fakeReferrer);

      vm = createComponent(Component, {
        projectUrl: fakeProjectUrl,
      }).$mount();

      expect(vm.goBackUrl).toEqual(fakeProjectUrl);
    });
  });
});
