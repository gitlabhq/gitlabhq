import Vue from 'vue';
import collapsibleComponent from '~/registry/components/collapsible_container.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('collapsible registry container', () => {
  let vm;
  let Component;
  let mockData;

  beforeEach(() => {
    Component = Vue.extend(collapsibleComponent);
    mockData = {
      canDelete: true,
      destroyPath: 'path',
      id: '123',
      isLoading: false,
      list: [
        {
          tag: 'centos6',
          revision: 'b118ab5b0e90b7cb5127db31d5321ac14961d097516a8e0e72084b6cdc783b43',
          shortRevision: 'b118ab5b0',
          size: 19,
          layers: 10,
          location: 'location',
          createdAt: 1505828744434,
          destroyPath: 'path',
          canDelete: true,
        },
      ],
      location: 'location',
      name: 'foo',
      tagsPath: 'path',
      pagination: {
        perPage: 5,
        page: 1,
        total: 13,
        totalPages: 1,
        nextPage: null,
        previousPage: null,
      },
    };
    vm = mountComponent(Component, { repo: mockData });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('toggle', () => {
    it('should be closed by default', () => {
      expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
      expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-right');
    });

    it('should be open when user clicks on closed repo', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.container-image-tags')).toBeDefined();
        expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-up');
        done();
      });
    });

    it('should be closed when the user clicks on an opened repo', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        vm.$el.querySelector('.js-toggle-repo').click();
        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.container-image-tags')).toBe(null);
          expect(vm.$el.querySelector('.container-image-head i').className).toEqual('fa fa-chevron-right');
          done();
        });
      });
    });
  });

  describe('delete repo', () => {
    it('should be possible to delete a repo', () => {
      expect(vm.$el.querySelector('.js-remove-repo')).toBeDefined();
    });
  });

  describe('registry list', () => {
    it('should render a table with the registry list', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelectorAll('table tbody tr').length,
        ).toEqual(mockData.list.length);
        done();
      });
    });

    it('should render registry tag', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        const textRendered = vm.$el.querySelector('.table tbody tr').textContent.trim().replace(/\s\s+/g, ' ');
        expect(textRendered).toContain(mockData.list[0].tag);
        expect(textRendered).toContain(mockData.list[0].shortRevision);
        expect(textRendered).toContain(mockData.list[0].layers);
        expect(textRendered).toContain(mockData.list[0].size);
        done();
      });
    });

    it('should be possible to delete a registry', (done) => {
      vm.$el.querySelector('.js-toggle-repo').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.table tbody tr .js-delete-registry'),
        ).toBeDefined();
        done();
      });
    });

    describe('pagination', () => {
      it('should be possible to change the page', (done) => {
        vm.$el.querySelector('.js-toggle-repo').click();

        Vue.nextTick(() => {
          expect(vm.$el.querySelector('.gl-pagination')).toBeDefined();
          done();
        });
      });
    });
  });
});
