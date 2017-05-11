require('~/gl_dropdown');
require('~/blob/create_branch_dropdown');
require('~/blob/target_branch_dropdown');

describe('TargetBranchDropdown', () => {
  const fixtureTemplate = 'static/target_branch_dropdown.html.raw';
  let dropdown;

  function createDropdown() {
    const projectBranches = getJSONFixture('project_branches.json');
    const dropdownEl = document.querySelector('.js-project-branches-dropdown');
    dropdown = new gl.TargetBranchDropDown(dropdownEl);
    dropdown.cachedRefs = projectBranches;
    dropdown.refreshData();
    return dropdown;
  }

  function submitBtn() {
    return document.querySelector('button[type="submit"]');
  }

  function searchField() {
    return document.querySelector('.dropdown-page-one .dropdown-input-field');
  }

  function element() {
    return document.querySelectorAll('div.dropdown-content li a');
  }

  function elementAtIndex(index) {
    return element()[index];
  }

  function clickElementAtIndex(index) {
    elementAtIndex(index).click();
  }

  preloadFixtures(fixtureTemplate);

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
    createDropdown();
  });

  it('disable submit when branch is not selected', () => {
    document.querySelector('input[name="target_branch"]').value = null;
    clickElementAtIndex(1);

    expect(submitBtn().getAttribute('disabled')).toEqual('');
  });

  it('enable submit when a branch is selected', () => {
    clickElementAtIndex(1);

    expect(submitBtn().getAttribute('disabled')).toBe(null);
  });

  it('triggers change.branch event on a branch click', () => {
    spyOnEvent(dropdown.$dropdown, 'change.branch');
    clickElementAtIndex(0);

    expect('change.branch').toHaveBeenTriggeredOn(dropdown.$dropdown);
  });

  describe('dropdownData', () => {
    it('cache the refs', () => {
      const refs = dropdown.cachedRefs;
      dropdown.cachedRefs = null;

      dropdown.dropdownData(refs);

      expect(dropdown.cachedRefs).toEqual(refs);
    });

    it('returns the Branches with the newBranch and defaultBranch', () => {
      const refs = dropdown.cachedRefs;
      dropdown.branchInput.value = 'master';
      dropdown.newBranch = { id: 'new_branch', text: 'new_branch', title: 'new_branch' };

      const branches = dropdown.dropdownData(refs).Branches;

      expect(branches.length).toEqual(4);
      expect(branches[0]).toEqual(dropdown.newBranch);
      expect(branches[1]).toEqual({ id: 'master', text: 'master', title: 'master' });
      expect(branches[2]).toEqual({ id: 'development', text: 'development', title: 'development' });
      expect(branches[3]).toEqual({ id: 'staging', text: 'staging', title: 'staging' });
    });
  });

  describe('setNewBranch', () => {
    it('adds the new branch and select it', () => {
      const branchName = 'new_branch';

      dropdown.setNewBranch(branchName);

      expect(elementAtIndex(0)).toHaveClass('is-active');
      expect(elementAtIndex(0)).toContainHtml(branchName);
    });

    it("doesn't add a new branch if already exists in the list", () => {
      const branchName = elementAtIndex(0).text;
      const initialLength = element().length;

      dropdown.setNewBranch(branchName);

      expect(element().length).toEqual(initialLength);
    });

    it('clears the search filter', () => {
      const branchName = elementAtIndex(0).text;
      searchField().value = 'searching';

      dropdown.setNewBranch(branchName);

      expect(searchField().value).toEqual('');
    });
  });
});
