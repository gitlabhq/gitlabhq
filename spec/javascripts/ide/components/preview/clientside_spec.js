import Vue from 'vue';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { createStore } from '~/ide/stores';
import Clientside from '~/ide/components/preview/clientside.vue';
import timeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import { resetStore, file } from '../../helpers';

describe('IDE clientside preview', () => {
  let vm;
  let Component;

  beforeAll(() => {
    Component = Vue.extend(Clientside);
  });

  beforeEach(done => {
    const store = createStore();

    Vue.set(store.state.entries, 'package.json', {
      ...file('package.json'),
    });
    Vue.set(store.state, 'currentProjectId', 'gitlab-ce');
    Vue.set(store.state.projects, 'gitlab-ce', {
      visibility: 'public',
    });

    vm = createComponentWithStore(Component, store);

    spyOn(vm, 'getFileData').and.returnValue(Promise.resolve());
    spyOn(vm, 'getRawFileData').and.returnValue(Promise.resolve(''));
    spyOn(vm, 'initManager');

    vm.$mount();

    timeoutPromise()
      .then(() => vm.$nextTick())
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    resetStore(vm.$store);
  });

  describe('without main entry', () => {
    it('creates sandpack manager', () => {
      expect(vm.initManager).not.toHaveBeenCalled();
    });
  });

  describe('with main entry', () => {
    beforeEach(done => {
      Vue.set(
        vm.$store.state.entries['package.json'],
        'raw',
        JSON.stringify({
          main: 'index.js',
        }),
      );

      vm
        .$nextTick()
        .then(() => vm.initPreview())
        .then(vm.$nextTick)
        .then(done)
        .catch(done.fail);
    });

    it('creates sandpack manager', () => {
      expect(vm.initManager).toHaveBeenCalledWith(
        '#ide-preview',
        {
          files: jasmine.any(Object),
          entry: '/index.js',
          showOpenInCodeSandbox: true,
        },
        {
          fileResolver: {
            isFile: jasmine.any(Function),
            readFile: jasmine.any(Function),
          },
        },
      );
    });
  });

  describe('computed', () => {
    describe('normalizedEntries', () => {
      beforeEach(done => {
        vm.$store.state.entries['index.js'] = {
          ...file('index.js'),
          type: 'blob',
          raw: 'test',
        };
        vm.$store.state.entries['index2.js'] = {
          ...file('index2.js'),
          type: 'blob',
          content: 'content',
        };
        vm.$store.state.entries.tree = {
          ...file('tree'),
          type: 'tree',
        };
        vm.$store.state.entries.empty = {
          ...file('empty'),
          type: 'blob',
        };

        vm.$nextTick(done);
      });

      it('returns flattened list of blobs with content', () => {
        expect(vm.normalizedEntries).toEqual({
          '/index.js': {
            code: 'test',
          },
          '/index2.js': {
            code: 'content',
          },
        });
      });
    });

    describe('mainEntry', () => {
      it('returns false when package.json is empty', () => {
        expect(vm.mainEntry).toBe(false);
      });

      it('returns main key from package.json', done => {
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );

        vm.$nextTick(() => {
          expect(vm.mainEntry).toBe('index.js');

          done();
        });
      });
    });

    describe('showPreview', () => {
      it('returns false if no mainEntry', () => {
        expect(vm.showPreview).toBe(false);
      });

      it('returns false if loading', done => {
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );
        vm.loading = true;

        vm.$nextTick(() => {
          expect(vm.showPreview).toBe(false);

          done();
        });
      });

      it('returns true if not loading and mainEntry exists', done => {
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );
        vm.loading = false;

        vm.$nextTick(() => {
          expect(vm.showPreview).toBe(true);

          done();
        });
      });
    });

    describe('showEmptyState', () => {
      it('returns true if no mainEnry exists', () => {
        expect(vm.showEmptyState).toBe(true);
      });

      it('returns false if loading', done => {
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );
        vm.loading = true;

        vm.$nextTick(() => {
          expect(vm.showEmptyState).toBe(false);

          done();
        });
      });

      it('returns false if not loading and mainEntry exists', done => {
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );
        vm.loading = false;

        vm.$nextTick(() => {
          expect(vm.showEmptyState).toBe(false);

          done();
        });
      });
    });

    describe('showOpenInCodeSandbox', () => {
      it('returns true when visiblity is public', () => {
        expect(vm.showOpenInCodeSandbox).toBe(true);
      });

      it('returns false when visiblity is private', done => {
        vm.$store.state.projects['gitlab-ce'].visibility = 'private';

        vm.$nextTick(() => {
          expect(vm.showOpenInCodeSandbox).toBe(false);

          done();
        });
      });
    });

    describe('sandboxOpts', () => {
      beforeEach(done => {
        vm.$store.state.entries['index.js'] = {
          ...file('index.js'),
          type: 'blob',
          raw: 'test',
        };
        Vue.set(
          vm.$store.state.entries['package.json'],
          'raw',
          JSON.stringify({
            main: 'index.js',
          }),
        );

        vm.$nextTick(done);
      });

      it('returns sandbox options', () => {
        expect(vm.sandboxOpts).toEqual({
          files: {
            '/index.js': {
              code: 'test',
            },
            '/package.json': {
              code: '{"main":"index.js"}',
            },
          },
          entry: '/index.js',
          showOpenInCodeSandbox: true,
        });
      });
    });
  });

  describe('methods', () => {
    describe('loadFileContent', () => {
      it('calls getFileData', () => {
        expect(vm.getFileData).toHaveBeenCalledWith({
          path: 'package.json',
          makeFileActive: false,
        });
      });

      it('calls getRawFileData', () => {
        expect(vm.getRawFileData).toHaveBeenCalledWith({ path: 'package.json' });
      });
    });

    describe('update', () => {
      beforeEach(() => {
        jasmine.clock().install();
        vm.manager.updatePreview = jasmine.createSpy('updatePreview');
        vm.manager.listener = jasmine.createSpy('updatePreview');
      });

      afterEach(() => {
        jasmine.clock().uninstall();
      });

      it('calls initPreview if manager is empty', () => {
        spyOn(vm, 'initPreview');
        vm.manager = {};

        vm.update();

        jasmine.clock().tick(500);

        expect(vm.initPreview).toHaveBeenCalled();
      });

      it('calls updatePreview', () => {
        vm.update();

        jasmine.clock().tick(500);

        expect(vm.manager.updatePreview).toHaveBeenCalledWith(vm.sandboxOpts);
      });
    });
  });

  describe('template', () => {
    it('renders ide-preview element when showPreview is true', done => {
      Vue.set(
        vm.$store.state.entries['package.json'],
        'raw',
        JSON.stringify({
          main: 'index.js',
        }),
      );
      vm.loading = false;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('#ide-preview')).not.toBe(null);
        done();
      });
    });

    it('renders empty state', done => {
      vm.loading = false;

      vm.$nextTick(() => {
        expect(vm.$el.textContent).toContain(
          'Preview your web application using Web IDE client-side evaluation.',
        );

        done();
      });
    });

    it('renders loading icon', done => {
      vm.loading = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.loading-container')).not.toBe(null);
        done();
      });
    });
  });
});
