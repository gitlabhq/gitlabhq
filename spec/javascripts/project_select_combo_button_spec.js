import ProjectSelectComboButton from '~/project_select_combo_button';

const fixturePath = 'static/project_select_combo_button.html.raw';

describe('Project Select Combo Button', () => {
  preloadFixtures(fixturePath);

  beforeEach(() => {
    this.defaults = {
      label: 'Select project to create issue',
      groupId: 12345,
      projectMeta: {
        name: 'My Cool Project',
        url: 'http://mycoolproject.com',
      },
      newProjectMeta: {
        name: 'My Other Cool Project',
        url: 'http://myothercoolproject.com',
      },
      localStorageKey: 'group-12345-new-issue-recent-project',
      relativePath: 'issues/new',
    };

    loadFixtures(fixturePath);

    this.newItemBtn = document.querySelector('.new-project-item-link');
    this.projectSelectInput = document.querySelector('.project-item-select');
  });

  describe('on page load when localStorage is empty', () => {
    beforeEach(() => {
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);
    });

    it('newItemBtn href is null', () => {
      expect(this.newItemBtn.getAttribute('href')).toBe('');
    });

    it('newItemBtn text is the plain default label', () => {
      expect(this.newItemBtn.textContent).toBe(this.defaults.label);
    });
  });

  describe('on page load when localStorage is filled', () => {
    beforeEach(() => {
      window.localStorage
        .setItem(this.defaults.localStorageKey, JSON.stringify(this.defaults.projectMeta));
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);
    });

    it('newItemBtn href is correctly set', () => {
      expect(this.newItemBtn.getAttribute('href')).toBe(this.defaults.projectMeta.url);
    });

    it('newItemBtn text is the cached label', () => {
      expect(this.newItemBtn.textContent)
        .toBe(`New issue in ${this.defaults.projectMeta.name}`);
    });

    afterEach(() => {
      window.localStorage.clear();
    });
  });

  describe('after selecting a new project', () => {
    beforeEach(() => {
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);

      // mock the effect of selecting an item from the projects dropdown (select2)
      $('.project-item-select')
        .val(JSON.stringify(this.defaults.newProjectMeta))
        .trigger('change');
    });

    it('newItemBtn href is correctly set', () => {
      expect(this.newItemBtn.getAttribute('href'))
        .toBe('http://myothercoolproject.com/issues/new');
    });

    it('newItemBtn text is the selected project label', () => {
      expect(this.newItemBtn.textContent)
        .toBe(`New issue in ${this.defaults.newProjectMeta.name}`);
    });

    afterEach(() => {
      window.localStorage.clear();
    });
  });

  describe('deriveTextVariants', () => {
    beforeEach(() => {
      this.mockExecutionContext = {
        resourceType: '',
        resourceLabel: '',
      };

      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);

      this.method = this.comboButton.deriveTextVariants.bind(this.mockExecutionContext);
    });

    it('correctly derives test variants for merge requests', () => {
      this.mockExecutionContext.resourceType = 'merge_requests';
      this.mockExecutionContext.resourceLabel = 'New merge request';

      const returnedVariants = this.method();

      expect(returnedVariants.localStorageItemType).toBe('new-merge-request');
      expect(returnedVariants.defaultTextPrefix).toBe('New merge request');
      expect(returnedVariants.presetTextSuffix).toBe('merge request');
    });

    it('correctly derives text variants for issues', () => {
      this.mockExecutionContext.resourceType = 'issues';
      this.mockExecutionContext.resourceLabel = 'New issue';

      const returnedVariants = this.method();

      expect(returnedVariants.localStorageItemType).toBe('new-issue');
      expect(returnedVariants.defaultTextPrefix).toBe('New issue');
      expect(returnedVariants.presetTextSuffix).toBe('issue');
    });
  });
});

