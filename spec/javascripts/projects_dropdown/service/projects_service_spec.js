import Vue from 'vue';
import VueResource from 'vue-resource';

import bp from '~/breakpoints';
import ProjectsService from '~/projects_dropdown/service/projects_service';
import { FREQUENT_PROJECTS } from '~/projects_dropdown/constants';
import { currentSession, unsortedFrequents, sortedFrequents } from '../mock_data';

Vue.use(VueResource);

FREQUENT_PROJECTS.MAX_COUNT = 3;

describe('ProjectsService', () => {
  let service;

  beforeEach(() => {
    gon.api_version = currentSession.apiVersion;
    gon.current_user_id = 1;
    service = new ProjectsService(currentSession.username);
  });

  describe('contructor', () => {
    it('should initialize default properties of class', () => {
      expect(service.isLocalStorageAvailable).toBeTruthy();
      expect(service.currentUserName).toBe(currentSession.username);
      expect(service.storageKey).toBe(currentSession.storageKey);
      expect(service.projectsPath).toBeDefined();
    });
  });

  describe('getSearchedProjects', () => {
    it('should return promise from VueResource HTTP GET', () => {
      spyOn(service.projectsPath, 'get').and.stub();

      const searchQuery = 'lab';
      const queryParams = {
        simple: true,
        per_page: 20,
        membership: true,
        order_by: 'last_activity_at',
        search: searchQuery,
      };

      service.getSearchedProjects(searchQuery);
      expect(service.projectsPath.get).toHaveBeenCalledWith(queryParams);
    });
  });

  describe('logProjectAccess', () => {
    let storage;

    beforeEach(() => {
      storage = {};

      spyOn(window.localStorage, 'setItem').and.callFake((storageKey, value) => {
        storage[storageKey] = value;
      });

      spyOn(window.localStorage, 'getItem').and.callFake((storageKey) => {
        if (storage[storageKey]) {
          return storage[storageKey];
        }

        return null;
      });
    });

    it('should create a project store if it does not exist and adds a project', () => {
      service.logProjectAccess(currentSession.project);

      const projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects.length).toBe(1);
      expect(projects[0].frequency).toBe(1);
      expect(projects[0].lastAccessedOn).toBeDefined();
    });

    it('should prevent inserting same report multiple times into store', () => {
      service.logProjectAccess(currentSession.project);
      service.logProjectAccess(currentSession.project);

      const projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects.length).toBe(1);
    });

    it('should increase frequency of report if it was logged multiple times over the course of an hour', () => {
      let projects;
      spyOn(Math, 'abs').and.returnValue(3600001); // this will lead to `diff` > 1;
      service.logProjectAccess(currentSession.project);

      projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects[0].frequency).toBe(1);

      service.logProjectAccess(currentSession.project);
      projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects[0].frequency).toBe(2);
      expect(projects[0].lastAccessedOn).not.toBe(currentSession.project.lastAccessedOn);
    });

    it('should always update project metadata', () => {
      let projects;
      const oldProject = {
        ...currentSession.project,
      };

      const newProject = {
        ...currentSession.project,
        name: 'New Name',
        avatarUrl: 'new/avatar.png',
        namespace: 'New / Namespace',
        webUrl: 'http://localhost/new/web/url',
      };

      service.logProjectAccess(oldProject);
      projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects[0].name).toBe(oldProject.name);
      expect(projects[0].avatarUrl).toBe(oldProject.avatarUrl);
      expect(projects[0].namespace).toBe(oldProject.namespace);
      expect(projects[0].webUrl).toBe(oldProject.webUrl);

      service.logProjectAccess(newProject);
      projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects[0].name).toBe(newProject.name);
      expect(projects[0].avatarUrl).toBe(newProject.avatarUrl);
      expect(projects[0].namespace).toBe(newProject.namespace);
      expect(projects[0].webUrl).toBe(newProject.webUrl);
    });

    it('should not add more than 20 projects in store', () => {
      for (let i = 1; i <= 5; i += 1) {
        const project = Object.assign(currentSession.project, { id: i });
        service.logProjectAccess(project);
      }

      const projects = JSON.parse(storage[currentSession.storageKey]);
      expect(projects.length).toBe(3);
    });
  });

  describe('getTopFrequentProjects', () => {
    let storage = {};

    beforeEach(() => {
      storage[currentSession.storageKey] = JSON.stringify(unsortedFrequents);

      spyOn(window.localStorage, 'getItem').and.callFake((storageKey) => {
        if (storage[storageKey]) {
          return storage[storageKey];
        }

        return null;
      });
    });

    it('should return top 5 frequently accessed projects for desktop screens', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('md');
      const frequentProjects = service.getTopFrequentProjects();

      expect(frequentProjects.length).toBe(5);
      frequentProjects.forEach((project, index) => {
        expect(project.id).toBe(sortedFrequents[index].id);
      });
    });

    it('should return top 3 frequently accessed projects for mobile screens', () => {
      spyOn(bp, 'getBreakpointSize').and.returnValue('sm');
      const frequentProjects = service.getTopFrequentProjects();

      expect(frequentProjects.length).toBe(3);
      frequentProjects.forEach((project, index) => {
        expect(project.id).toBe(sortedFrequents[index].id);
      });
    });

    it('should return empty array if there are no projects available in store', () => {
      storage = {};
      expect(service.getTopFrequentProjects().length).toBe(0);
    });
  });
});
