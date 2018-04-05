import Vue from 'vue';
import repoFileButtons from '~/ide/components/ide_file_buttons.vue';
import createVueComponent from '../../helpers/vue_mount_component_helper';
import { file } from '../helpers';

describe('RepoFileButtons', () => {
  const activeFile = file();
  let vm;

  function createComponent() {
    const RepoFileButtons = Vue.extend(repoFileButtons);

    activeFile.rawPath = 'test';
    activeFile.blamePath = 'test';
    activeFile.commitsPath = 'test';

    return createVueComponent(RepoFileButtons, {
      file: activeFile,
    });
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders Raw, Blame, History and Permalink', done => {
    vm = createComponent();

    vm.$nextTick(() => {
      const raw = vm.$el.querySelector('.raw');
      const blame = vm.$el.querySelector('.blame');
      const history = vm.$el.querySelector('.history');

      expect(raw.href).toMatch(`/${activeFile.rawPath}`);
      expect(raw.getAttribute('data-original-title')).toEqual('Raw');
      expect(blame.href).toMatch(`/${activeFile.blamePath}`);
      expect(blame.getAttribute('data-original-title')).toEqual('Blame');
      expect(history.href).toMatch(`/${activeFile.commitsPath}`);
      expect(history.getAttribute('data-original-title')).toEqual('History');
      expect(vm.$el.querySelector('.permalink').getAttribute('data-original-title')).toEqual(
        'Permalink',
      );

      done();
    });
  });

  it('renders Download', done => {
    activeFile.binary = true;
    vm = createComponent();

    vm.$nextTick(() => {
      const raw = vm.$el.querySelector('.raw');

      expect(raw.href).toMatch(`/${activeFile.rawPath}`);
      expect(raw.getAttribute('data-original-title')).toEqual('Download');

      done();
    });
  });
});
