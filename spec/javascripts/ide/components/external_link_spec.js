import Vue from 'vue';
import externalLink from '~/ide/components/external_link.vue';
import createVueComponent from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('ExternalLink', () => {
  const activeFile = file();
  let vm;

  function createComponent() {
    const ExternalLink = Vue.extend(externalLink);

    activeFile.permalink = 'test';

    return createVueComponent(ExternalLink, {
      file: activeFile,
    });
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders the external link with the correct href', done => {
    activeFile.binary = true;
    vm = createComponent();

    vm.$nextTick(() => {
      const openLink = vm.$el.querySelector('a');

      expect(openLink.href).toMatch(`/${activeFile.permalink}`);
      done();
    });
  });
});
