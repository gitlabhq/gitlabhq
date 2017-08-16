import ProjectSelectComboButton from '~/project_select_combo_button';

const fixturePath = 'static/project_select_combo_button.html.raw';

describe('Project Select Combo Button', function () {
  preloadFixtures(fixturePath);

  beforeEach(function () {
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

  describe('on page load when localStorage is empty', function () {
    beforeEach(function () {
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);
    });

    it('newItemBtn is disabled', function () {
      expect(this.newItemBtn.hasAttribute('disabled')).toBe(true);
      expect(this.newItemBtn.classList.contains('disabled')).toBe(true);
    });

    it('newItemBtn href is null', function () {
      expect(this.newItemBtn.getAttribute('href')).toBe('');
    });

    it('newItemBtn text is the plain default label', function () {
      expect(this.newItemBtn.textContent).toBe(this.defaults.label);
    });
  });

  describe('on page load when localStorage is filled', function () {
    beforeEach(function () {
      window.localStorage
        .setItem(this.defaults.localStorageKey, JSON.stringify(this.defaults.projectMeta));
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);
    });

    it('newItemBtn is not disabled', function () {
      expect(this.newItemBtn.hasAttribute('disabled')).toBe(false);
      expect(this.newItemBtn.classList.contains('disabled')).toBe(false);
    });

    it('newItemBtn href is correctly set', function () {
      expect(this.newItemBtn.getAttribute('href')).toBe(this.defaults.projectMeta.url);
    });

    it('newItemBtn text is the cached label', function () {
      expect(this.newItemBtn.textContent)
        .toBe(`New issue in ${this.defaults.projectMeta.name}`);
    });

    afterEach(function () {
      window.localStorage.clear();
    });
  });

  describe('after selecting a new project', function () {
    beforeEach(function () {
      this.comboButton = new ProjectSelectComboButton(this.projectSelectInput);

      // mock the effect of selecting an item from the projects dropdown (select2)
      $('.project-item-select')
        .val(JSON.stringify(this.defaults.newProjectMeta))
        .trigger('change');
    });

    it('newItemBtn is not disabled', function () {
      expect(this.newItemBtn.hasAttribute('disabled')).toBe(false);
      expect(this.newItemBtn.classList.contains('disabled')).toBe(false);
    });

    it('newItemBtn href is correctly set', function () {
      expect(this.newItemBtn.getAttribute('href'))
        .toBe('http://myothercoolproject.com/issues/new');
    });

    it('newItemBtn text is the selected project label', function () {
      expect(this.newItemBtn.textContent)
        .toBe(`New issue in ${this.defaults.newProjectMeta.name}`);
    });

    afterEach(function () {
      window.localStorage.clear();
    });
  });
});

