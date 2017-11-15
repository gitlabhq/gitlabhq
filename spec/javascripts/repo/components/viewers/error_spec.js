import Vue from 'vue';
import store from '~/repo/stores';
import htmlPreview from '~/repo/components/viewers/error.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('Multi-file editor error viewer', () => {
  let vm;
  let f;

  beforeEach((done) => {
    const Comp = Vue.extend(htmlPreview);
    f = file();

    Object.assign(f, {
      active: true,
      rawPath: 'rawPath',
      rich: Object.assign(f.rich, { name: 'image', renderError: 'it is too large' }),
    });

    vm = createComponentWithStore(Comp, store);
    vm.$store.state.openFiles.push(f);

    vm.$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders error message', () => {
    expect(
      vm.$el.textContent.trim(),
    ).toContain('The image could not be displayed because it is too large');
  });

  it('renders download link', () => {
    const link = vm.$el.querySelector('a');

    expect(
      link.textContent.trim(),
    ).toBe('download it');
    expect(
      link.getAttribute('href'),
    ).toBe('rawPath');
  });
});
