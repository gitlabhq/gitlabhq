import Vue from 'vue';
import store from '~/repo/stores';
import htmlPreview from '~/repo/components/viewers/html.vue';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { file, resetStore } from '../../helpers';

describe('Multi-file editor HTML viewer', () => {
  let vm;
  let f;

  beforeEach((done) => {
    const Comp = Vue.extend(htmlPreview);
    f = file();

    Object.assign(f, {
      active: true,
      rich: Object.assign(f.rich, { html: 'richHTML' }),
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

  it('renders loading icon', () => {
    expect(vm.$el.querySelector('.fa-spinner')).not.toBeNull();
  });

  it('renders HTML output', (done) => {
    f.rich.loading = false;

    setTimeout(() => {
      expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
      expect(vm.$el.textContent.trim()).toBe('richHTML');

      done();
    });
  });
});
