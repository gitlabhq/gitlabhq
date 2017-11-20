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
      rich: Object.assign(f.rich, {
        name: 'image',
        renderErrorReason: 'it is too large',
        renderError: 'collapsed',
      }),
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
      vm.$el.textContent.replace(/\s+/g, ' ').trim(),
    ).toContain('The image could not be displayed because it is too large');
  });

  it('renders download link', () => {
    expect(
      vm.$el.textContent.trim(),
    ).toContain('download it');
  });

  describe('collapsed', () => {
    beforeEach(() => {
      spyOn(vm, 'getFileHTML');
    });

    it('calls getFileHTML with override when clicking load anyway link', () => {
      vm.$el.querySelector('a').click();

      expect(vm.getFileHTML).toHaveBeenCalledWith({
        file: f,
        override: true,
      });
    });
  });

  describe('too_large', () => {
    beforeEach((done) => {
      f.simple.name = 'text';
      f.rich.renderError = 'too_large';

      spyOn(vm, 'changeFileViewer');

      Vue.nextTick(done);
    });

    it('renders view source link', () => {
      expect(
        vm.$el.querySelector('a').textContent.trim(),
      ).toBe('view the source');
    });

    it('calls changeFileViewer with simple type', () => {
      vm.$el.querySelector('a').click();

      expect(vm.changeFileViewer).toHaveBeenCalledWith({
        file: f,
        type: 'simple',
      });
    });
  });

  describe('server_side_but_stored_externally', () => {
    beforeEach((done) => {
      f.simple.name = 'text';
      f.rich.renderError = 'server_side_but_stored_externally';

      spyOn(vm, 'changeFileViewer');

      Vue.nextTick(done);
    });

    it('renders view source link', () => {
      expect(
        vm.$el.querySelector('a').textContent.trim(),
      ).toBe('view the source');
    });

    it('calls changeFileViewer with simple type', () => {
      vm.$el.querySelector('a').click();

      expect(vm.changeFileViewer).toHaveBeenCalledWith({
        file: f,
        type: 'simple',
      });
    });
  });
});
