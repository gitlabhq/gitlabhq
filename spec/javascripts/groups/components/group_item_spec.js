import Vue from 'vue';
import groupItemComponent from '~/groups/components/group_item.vue';
import groupFolderComponent from '~/groups/components/group_folder.vue';
import eventHub from '~/groups/event_hub';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { mockParentGroupItem, mockChildren } from '../mock_data';

const createComponent = (group = mockParentGroupItem, parentGroup = mockChildren[0]) => {
  const Component = Vue.extend(groupItemComponent);

  return mountComponent(Component, {
    group,
    parentGroup,
  });
};

describe('GroupItemComponent', () => {
  let vm;

  beforeEach((done) => {
    Vue.component('group-folder', groupFolderComponent);

    vm = createComponent();

    Vue.nextTick(() => {
      done();
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('groupDomId', () => {
      it('should return ID string suffixed with group ID', () => {
        expect(vm.groupDomId).toBe('group-55');
      });
    });

    describe('rowClass', () => {
      it('should return map of classes based on group details', () => {
        const classes = ['is-open', 'has-children', 'has-description', 'being-removed'];
        const rowClass = vm.rowClass;

        expect(Object.keys(rowClass).length).toBe(classes.length);
        Object.keys(rowClass).forEach((className) => {
          expect(classes.indexOf(className) > -1).toBeTruthy();
        });
      });
    });

    describe('hasChildren', () => {
      it('should return boolean value representing if group has any children present', () => {
        let newVm;
        const group = Object.assign({}, mockParentGroupItem);

        group.childrenCount = 5;
        newVm = createComponent(group);
        expect(newVm.hasChildren).toBeTruthy();
        newVm.$destroy();

        group.childrenCount = 0;
        newVm = createComponent(group);
        expect(newVm.hasChildren).toBeFalsy();
        newVm.$destroy();
      });
    });

    describe('hasAvatar', () => {
      it('should return boolean value representing if group has any avatar present', () => {
        let newVm;
        const group = Object.assign({}, mockParentGroupItem);

        group.avatarUrl = null;
        newVm = createComponent(group);
        expect(newVm.hasAvatar).toBeFalsy();
        newVm.$destroy();

        group.avatarUrl = '/uploads/group_avatar.png';
        newVm = createComponent(group);
        expect(newVm.hasAvatar).toBeTruthy();
        newVm.$destroy();
      });
    });

    describe('isGroup', () => {
      it('should return boolean value representing if group item is of type `group` or not', () => {
        let newVm;
        const group = Object.assign({}, mockParentGroupItem);

        group.type = 'group';
        newVm = createComponent(group);
        expect(newVm.isGroup).toBeTruthy();
        newVm.$destroy();

        group.type = 'project';
        newVm = createComponent(group);
        expect(newVm.isGroup).toBeFalsy();
        newVm.$destroy();
      });
    });
  });

  describe('methods', () => {
    describe('onClickRowGroup', () => {
      let event;

      beforeEach(() => {
        const classList = {
          contains() {
            return false;
          },
        };

        event = {
          target: {
            classList,
            parentElement: {
              classList,
            },
          },
        };
      });

      it('should emit `toggleChildren` event when expand is clicked on a group and it has children present', () => {
        spyOn(eventHub, '$emit');

        vm.onClickRowGroup(event);
        expect(eventHub.$emit).toHaveBeenCalledWith('toggleChildren', vm.group);
      });

      it('should navigate page to group homepage if group does not have any children present', (done) => {
        const group = Object.assign({}, mockParentGroupItem);
        group.childrenCount = 0;
        const newVm = createComponent(group);
        const visitUrl = spyOnDependency(groupItemComponent, 'visitUrl').and.stub();
        spyOn(eventHub, '$emit');

        newVm.onClickRowGroup(event);
        setTimeout(() => {
          expect(eventHub.$emit).not.toHaveBeenCalled();
          expect(visitUrl).toHaveBeenCalledWith(newVm.group.relativePath);
          done();
        }, 0);
      });
    });
  });

  describe('template', () => {
    it('should render component template correctly', () => {
      expect(vm.$el.getAttribute('id')).toBe('group-55');
      expect(vm.$el.classList.contains('group-row')).toBeTruthy();

      expect(vm.$el.querySelector('.group-row-contents')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .controls')).toBeDefined();
      expect(vm.$el.querySelector('.group-row-contents .stats')).toBeDefined();

      expect(vm.$el.querySelector('.folder-toggle-wrap')).toBeDefined();
      expect(vm.$el.querySelector('.folder-toggle-wrap .folder-caret')).toBeDefined();
      expect(vm.$el.querySelector('.folder-toggle-wrap .item-type-icon')).toBeDefined();

      expect(vm.$el.querySelector('.avatar-container')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container a.no-expand')).toBeDefined();
      expect(vm.$el.querySelector('.avatar-container .avatar')).toBeDefined();

      expect(vm.$el.querySelector('.title')).toBeDefined();
      expect(vm.$el.querySelector('.title a.no-expand')).toBeDefined();
      expect(vm.$el.querySelector('.access-type')).toBeDefined();
      expect(vm.$el.querySelector('.description')).toBeDefined();

      expect(vm.$el.querySelector('.group-list-tree')).toBeDefined();
    });
  });
});
