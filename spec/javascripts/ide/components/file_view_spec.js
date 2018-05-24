import Vue from 'vue';
import fileView from '~/ide/components/file_view.vue';
import createVueComponent from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('FileView', () => {
  const activeFile = file();
  let vm;

  function createComponent() {
    const FileView = Vue.extend(fileView);

    activeFile.permalink = 'test';

    return createVueComponent(FileView, {
      file: activeFile,
    });
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders Download', done => {
    activeFile.binary = true;
    vm = createComponent();

    vm.$nextTick(() => {
      const openLink = vm.$el.querySelector('a');

      expect(openLink.href).toMatch(`/${activeFile.permalink}`);
      done();
    });
  });
});
