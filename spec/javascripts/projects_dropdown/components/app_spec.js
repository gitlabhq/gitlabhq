import Vue from 'vue';

import bp from '~/breakpoints';
import appComponent from '~/projects_dropdown/components/app.vue';
import eventHub from '~/projects_dropdown/event_hub';
import ProjectsStore from '~/projects_dropdown/store/projects_store';
import ProjectsService from '~/projects_dropdown/service/projects_service';

import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { currentSession, mockProject, mockRawProject } from '../mock_data';

const createComponent = () => {
  gon.api_version = currentSession.apiVersion;
  const Component = Vue.extend(appComponent);
  const store = new ProjectsStore();
  const service = new ProjectsService(currentSession.username);

  return mountComponent(Component, {
    store,
    service,
    currentUserName: currentSession.username,
    currentProject: currentSession.project,
  });
};

const returnServicePromise = (data, failed) => new Promise((resolve, reject) => {
  if (failed) {
    reject(data);
  } else {
    resolve({
      json() {
        return data;
      },
    });
  }
});

describe('AppComponent', () => {
  describe('computed', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('frequentProjects', () => {
      it('should return list of frequently accessed projects from store', () => {
        expect(vm.frequentProjects).toBeDefined();
        expect(vm.frequentProjects.length).toBe(0);

        vm.store.setFrequentProjects([mockProject]);
        expect(vm.frequentProjects).toBeDefined();
        expect(vm.frequentProjects.length).toBe(1);
      });
    });

    describe('searchProjects', () => {
      it('should return list of frequently accessed projects from store', () => {
        expect(vm.searchProjects).toBeDefined();
        expect(vm.searchProjects.length).toBe(0);

        vm.store.setSearchedProjects([mockRawProject]);
        expect(vm.searchProjects).toBeDefined();
        expect(vm.searchProjects.length).toBe(1);
      });
    });
  });

  describe('methods', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('toggleFrequentProjectsList', () => {
      it('should toggle props which control visibility of Frequent Projects list from state passed', () => {
        vm.toggleFrequentProjectsList(true);
        expect(vm.isLoadingProjects).toBeFalsy();
        expect(vm.isSearchListVisible).toBeFalsy();
        expect(vm.isFrequentsListVisible).toBeTruthy();

        vm.toggleFrequentProjectsList(false);
        expect(vm.isLoadingProjects).toBeTruthy();
        expect(vm.isSearchListVisible).toBeTruthy();
        expect(vm.isFrequentsListVisible).toBeFalsy();
      });
    });

    describe('toggleSearchProjectsList', () => {
      it('should toggle props which control visibility of Searched Projects list from state passed', () => {
        vm.toggleSearchProjectsList(true);
        expect(vm.isLoadingProjects).toBeFalsy();
        expect(vm.isFrequentsListVisible).toBeFalsy();
        expect(vm.isSearchListVisible).toBeTruthy();

        vm.toggleSearchProjectsList(false);
        expect(vm.isLoadingProjects).toBeTruthy();
        expect(vm.isFrequentsListVisible).toBeTruthy();
        expect(vm.isSearchListVisible).toBeFalsy();
      });
    });

    describe('toggleLoader', () => {
      it('should toggle props which control visibility of list loading animation from state passed', () => {
        vm.toggleLoader(true);
        expect(vm.isFrequentsListVisible).toBeFalsy();
        expect(vm.isSearchListVisible).toBeFalsy();
        expect(vm.isLoadingProjects).toBeTruthy();

        vm.toggleLoader(false);
        expect(vm.isFrequentsListVisible).toBeTruthy();
        expect(vm.isSearchListVisible).toBeTruthy();
        expect(vm.isLoadingProjects).toBeFalsy();
      });
    });

    describe('fetchFrequentProjects', () => {
      it('should set props for loading animation to `true` while frequent projects list is being loaded', () => {
        spyOn(vm, 'toggleLoader');

        vm.fetchFrequentProjects();
        expect(vm.isLocalStorageFailed).toBeFalsy();
        expect(vm.toggleLoader).toHaveBeenCalledWith(true);
      });

      it('should set props for loading animation to `false` and props for frequent projects list to `true` once data is loaded', () => {
        const mockData = [mockProject];

        spyOn(vm.service, 'getFrequentProjects').and.returnValue(mockData);
        spyOn(vm.store, 'setFrequentProjects');
        spyOn(vm, 'toggleFrequentProjectsList');

        vm.fetchFrequentProjects();
        expect(vm.service.getFrequentProjects).toHaveBeenCalled();
        expect(vm.store.setFrequentProjects).toHaveBeenCalledWith(mockData);
        expect(vm.toggleFrequentProjectsList).toHaveBeenCalledWith(true);
      });

      it('should set props for failure message to `true` when method fails to fetch frequent projects list', () => {
        spyOn(vm.service, 'getFrequentProjects').and.returnValue(null);
        spyOn(vm.store, 'setFrequentProjects');
        spyOn(vm, 'toggleFrequentProjectsList');

        expect(vm.isLocalStorageFailed).toBeFalsy();

        vm.fetchFrequentProjects();
        expect(vm.service.getFrequentProjects).toHaveBeenCalled();
        expect(vm.store.setFrequentProjects).toHaveBeenCalledWith([]);
        expect(vm.toggleFrequentProjectsList).toHaveBeenCalledWith(true);
        expect(vm.isLocalStorageFailed).toBeTruthy();
      });

      it('should set props for search results list to `true` if search query was already made previously', () => {
        spyOn(bp, 'getBreakpointSize').and.returnValue('md');
        spyOn(vm.service, 'getFrequentProjects');
        spyOn(vm, 'toggleSearchProjectsList');

        vm.searchQuery = 'test';
        vm.fetchFrequentProjects();
        expect(vm.service.getFrequentProjects).not.toHaveBeenCalled();
        expect(vm.toggleSearchProjectsList).toHaveBeenCalledWith(true);
      });

      it('should set props for frequent projects list to `true` if search query was already made but screen size is less than 768px', () => {
        spyOn(bp, 'getBreakpointSize').and.returnValue('sm');
        spyOn(vm, 'toggleSearchProjectsList');
        spyOn(vm.service, 'getFrequentProjects');

        vm.searchQuery = 'test';
        vm.fetchFrequentProjects();
        expect(vm.service.getFrequentProjects).toHaveBeenCalled();
        expect(vm.toggleSearchProjectsList).not.toHaveBeenCalled();
      });
    });

    describe('fetchSearchedProjects', () => {
      const searchQuery = 'test';

      it('should perform search with provided search query', (done) => {
        const mockData = [mockRawProject];
        spyOn(vm, 'toggleLoader');
        spyOn(vm, 'toggleSearchProjectsList');
        spyOn(vm.service, 'getSearchedProjects').and.returnValue(returnServicePromise(mockData));
        spyOn(vm.store, 'setSearchedProjects');

        vm.fetchSearchedProjects(searchQuery);
        setTimeout(() => {
          expect(vm.searchQuery).toBe(searchQuery);
          expect(vm.toggleLoader).toHaveBeenCalledWith(true);
          expect(vm.service.getSearchedProjects).toHaveBeenCalledWith(searchQuery);
          expect(vm.toggleSearchProjectsList).toHaveBeenCalledWith(true);
          expect(vm.store.setSearchedProjects).toHaveBeenCalledWith(mockData);
          done();
        }, 0);
      });

      it('should update props for showing search failure', (done) => {
        spyOn(vm, 'toggleSearchProjectsList');
        spyOn(vm.service, 'getSearchedProjects').and.returnValue(returnServicePromise({}, true));

        vm.fetchSearchedProjects(searchQuery);
        setTimeout(() => {
          expect(vm.searchQuery).toBe(searchQuery);
          expect(vm.service.getSearchedProjects).toHaveBeenCalledWith(searchQuery);
          expect(vm.isSearchFailed).toBeTruthy();
          expect(vm.toggleSearchProjectsList).toHaveBeenCalledWith(true);
          done();
        }, 0);
      });
    });

    describe('logCurrentProjectAccess', () => {
      it('should log current project access via service', (done) => {
        spyOn(vm.service, 'logProjectAccess');

        vm.currentProject = mockProject;
        vm.logCurrentProjectAccess();

        setTimeout(() => {
          expect(vm.service.logProjectAccess).toHaveBeenCalledWith(mockProject);
          done();
        }, 1);
      });
    });

    describe('handleSearchClear', () => {
      it('should show frequent projects list when search input is cleared', () => {
        spyOn(vm.store, 'clearSearchedProjects');
        spyOn(vm, 'toggleFrequentProjectsList');

        vm.handleSearchClear();

        expect(vm.toggleFrequentProjectsList).toHaveBeenCalledWith(true);
        expect(vm.store.clearSearchedProjects).toHaveBeenCalled();
        expect(vm.searchQuery).toBe('');
      });
    });

    describe('handleSearchFailure', () => {
      it('should show failure message within dropdown', () => {
        spyOn(vm, 'toggleSearchProjectsList');

        vm.handleSearchFailure();
        expect(vm.toggleSearchProjectsList).toHaveBeenCalledWith(true);
        expect(vm.isSearchFailed).toBeTruthy();
      });
    });
  });

  describe('created', () => {
    it('should bind event listeners on eventHub', (done) => {
      spyOn(eventHub, '$on');

      createComponent().$mount();

      Vue.nextTick(() => {
        expect(eventHub.$on).toHaveBeenCalledWith('dropdownOpen', jasmine.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('searchProjects', jasmine.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('searchCleared', jasmine.any(Function));
        expect(eventHub.$on).toHaveBeenCalledWith('searchFailed', jasmine.any(Function));
        done();
      });
    });
  });

  describe('beforeDestroy', () => {
    it('should unbind event listeners on eventHub', (done) => {
      const vm = createComponent();
      spyOn(eventHub, '$off');

      vm.$mount();
      vm.$destroy();

      Vue.nextTick(() => {
        expect(eventHub.$off).toHaveBeenCalledWith('dropdownOpen', jasmine.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('searchProjects', jasmine.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('searchCleared', jasmine.any(Function));
        expect(eventHub.$off).toHaveBeenCalledWith('searchFailed', jasmine.any(Function));
        done();
      });
    });
  });

  describe('template', () => {
    let vm;

    beforeEach(() => {
      vm = createComponent();
    });

    afterEach(() => {
      vm.$destroy();
    });

    it('should render search input', () => {
      expect(vm.$el.querySelector('.search-input-container')).toBeDefined();
    });

    it('should render loading animation', (done) => {
      vm.toggleLoader(true);
      Vue.nextTick(() => {
        const loadingEl = vm.$el.querySelector('.loading-animation');

        expect(loadingEl).toBeDefined();
        expect(loadingEl.classList.contains('prepend-top-20')).toBeTruthy();
        expect(loadingEl.querySelector('i').getAttribute('aria-label')).toBe('Loading projects');
        done();
      });
    });

    it('should render frequent projects list header', (done) => {
      vm.toggleFrequentProjectsList(true);
      Vue.nextTick(() => {
        const sectionHeaderEl = vm.$el.querySelector('.section-header');

        expect(sectionHeaderEl).toBeDefined();
        expect(sectionHeaderEl.innerText.trim()).toBe('Frequently visited');
        done();
      });
    });

    it('should render frequent projects list', (done) => {
      vm.toggleFrequentProjectsList(true);
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.projects-list-frequent-container')).toBeDefined();
        done();
      });
    });

    it('should render searched projects list', (done) => {
      vm.toggleSearchProjectsList(true);
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.section-header')).toBe(null);
        expect(vm.$el.querySelector('.projects-list-search-container')).toBeDefined();
        done();
      });
    });
  });
});
