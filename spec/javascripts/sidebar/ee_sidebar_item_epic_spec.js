import Vue from 'vue';
import CESidebarStore from '~/sidebar/stores/sidebar_store';
import SidebarStore from 'ee/sidebar/stores/sidebar_store';
import sidebarItemEpic from 'ee/sidebar/components/sidebar_item_epic.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('sidebarItemEpic', () => {
  let vm;
  let sidebarStore;

  beforeEach(() => {
    sidebarStore = new SidebarStore({
      currentUser: '',
      rootPath: '',
      editable: false,
    });

    const SidebarItemEpic = Vue.extend(sidebarItemEpic);
    vm = mountComponent(SidebarItemEpic, {});
  });

  afterEach(() => {
    vm.$destroy();
    CESidebarStore.singleton = null;
  });

  describe('loading', () => {
    it('shows loading icon', () => {
      expect(vm.$el.querySelector('.fa-spin')).toBeDefined();
    });

    it('hides collapsed title', () => {
      expect(vm.$el.querySelector('.sidebar-collapsed-icon .collapsed-truncated-title')).toBeNull();
    });
  });

  describe('loaded', () => {
    const epicTitle = 'epic title';
    const url = 'https://gitlab.com/';

    beforeEach((done) => {
      sidebarStore.setEpicData({
        epic: {
          title: epicTitle,
          id: 1,
          url,
        },
      });

      Vue.nextTick(done);
    });

    it('shows epic title', () => {
      expect(vm.$el.querySelector('.value').innerText.trim()).toEqual(epicTitle);
    });

    it('links epic title to epic url', () => {
      expect(vm.$el.querySelector('a').href).toEqual(url);
    });

    it('shows epic title as collapsed title tooltip', () => {
      expect(vm.$el.querySelector('.sidebar-collapsed-icon').getAttribute('title')).toBeDefined();
      expect(vm.$el.querySelector('.sidebar-collapsed-icon').getAttribute('data-original-title')).toEqual(epicTitle);
    });

    describe('no epic', () => {
      beforeEach((done) => {
        sidebarStore.epic = {};
        Vue.nextTick(done);
      });

      it('shows none as the epic text', () => {
        expect(vm.$el.querySelector('.value').innerText.trim()).toEqual('None');
      });

      it('shows none as the collapsed title', () => {
        expect(vm.$el.querySelector('.collapse-truncated-title').innerText.trim()).toEqual('None');
      });

      it('hides collapsed title tooltip', () => {
        expect(vm.$el.querySelector('.collapse-truncated-title').getAttribute('title')).toBeNull();
      });
    });
  });
});
