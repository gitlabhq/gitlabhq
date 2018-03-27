import ProjectsStore from '~/projects_dropdown/store/projects_store';
import { mockProject, mockRawProject } from '../mock_data';

describe('ProjectsStore', () => {
  let store;

  beforeEach(() => {
    store = new ProjectsStore();
  });

  describe('setFrequentProjects', () => {
    it('should set frequent projects list to state', () => {
      store.setFrequentProjects([mockProject]);

      expect(store.getFrequentProjects().length).toBe(1);
      expect(store.getFrequentProjects()[0].id).toBe(mockProject.id);
    });
  });

  describe('setSearchedProjects', () => {
    it('should set searched projects list to state', () => {
      store.setSearchedProjects([mockRawProject]);

      const processedProjects = store.getSearchedProjects();
      expect(processedProjects.length).toBe(1);
      expect(processedProjects[0].id).toBe(mockRawProject.id);
      expect(processedProjects[0].namespace).toBe(mockRawProject.name_with_namespace);
      expect(processedProjects[0].webUrl).toBe(mockRawProject.web_url);
      expect(processedProjects[0].avatarUrl).toBe(mockRawProject.avatar_url);
    });
  });

  describe('clearSearchedProjects', () => {
    it('should clear searched projects list from state', () => {
      store.setSearchedProjects([mockRawProject]);
      expect(store.getSearchedProjects().length).toBe(1);
      store.clearSearchedProjects();
      expect(store.getSearchedProjects().length).toBe(0);
    });
  });
});
