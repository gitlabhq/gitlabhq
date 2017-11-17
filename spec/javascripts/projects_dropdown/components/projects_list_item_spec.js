import Vue from 'vue';

import projectsListItemComponent from '~/projects_dropdown/components/projects_list_item.vue';

import mountComponent from '../../helpers/vue_mount_component_helper';
import { mockProject } from '../mock_data';

const createComponent = () => {
  const Component = Vue.extend(projectsListItemComponent);

  return mountComponent(Component, {
    projectId: mockProject.id,
    projectName: mockProject.name,
    namespace: mockProject.namespace,
    webUrl: mockProject.webUrl,
    avatarUrl: mockProject.avatarUrl,
  });
};

describe('ProjectsListItemComponent', () => {
  let vm;

  beforeEach(() => {
    vm = createComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed', () => {
    describe('hasAvatar', () => {
      it('should return `true` or `false` if whether avatar is present or not', () => {
        vm.avatarUrl = 'path/to/avatar.png';
        expect(vm.hasAvatar).toBeTruthy();

        vm.avatarUrl = null;
        expect(vm.hasAvatar).toBeFalsy();
      });
    });

    describe('highlightedProjectName', () => {
      it('should enclose part of project name in <b> & </b> which matches with `matcher` prop', () => {
        vm.matcher = 'lab';
        expect(vm.highlightedProjectName).toContain('<b>Lab</b>');
      });

      it('should return project name as it is if `matcher` is not available', () => {
        vm.matcher = null;
        expect(vm.highlightedProjectName).toBe(mockProject.name);
      });

      it('should truncate project name if it exceeds 40 characters', () => {
        vm.projectName = 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310';
        expect(vm.highlightedProjectName).not.toBe(vm.projectName);

        vm.projectName = 'platform / hardware';
        expect(vm.highlightedProjectName).toBe(vm.projectName);
      });
    });

    describe('truncatedNamespace', () => {
      it('should truncate namespace string if it exceeds 45 characters', () => {
        vm.namespace = 'platform / hardware / broadcom / Wifi Group / Mobile Chipset / nokia-3310';
        expect(vm.truncatedNamespace).not.toBe(vm.namespace);

        vm.namespace = 'platform / hardware';
        expect(vm.truncatedNamespace).toBe(vm.namespace);
      });
    });
  });

  describe('template', () => {
    it('should render component element', () => {
      expect(vm.$el.classList.contains('projects-list-item-container')).toBeTruthy();
      expect(vm.$el.querySelectorAll('a').length).toBe(1);
      expect(vm.$el.querySelectorAll('.project-item-avatar-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.project-item-metadata-container').length).toBe(1);
      expect(vm.$el.querySelectorAll('.project-title').length).toBe(1);
      expect(vm.$el.querySelectorAll('.project-namespace').length).toBe(1);
    });
  });
});
