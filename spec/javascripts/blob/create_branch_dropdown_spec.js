import '~/gl_dropdown';
import '~/blob/create_branch_dropdown';
import '~/blob/target_branch_dropdown';

describe('CreateBranchDropdown', () => {
  const fixtureTemplate = 'static/target_branch_dropdown.html.raw';
  // selectors
  const createBranchSel = '.js-new-branch-btn';
  const backBtnSel = '.dropdown-menu-back';
  const cancelBtnSel = '.js-cancel-branch-btn';
  const branchNameSel = '#new_branch_name';
  const branchName = 'new_name';
  let dropdown;

  function createDropdown() {
    const dropdownEl = document.querySelector('.js-project-branches-dropdown');
    const projectBranches = getJSONFixture('project_branches.json');
    dropdown = new gl.TargetBranchDropDown(dropdownEl);
    dropdown.cachedRefs = projectBranches;
    return dropdown;
  }

  function createBranchBtn() {
    return document.querySelector(createBranchSel);
  }

  function backBtn() {
    return document.querySelector(backBtnSel);
  }

  function cancelBtn() {
    return document.querySelector(cancelBtnSel);
  }

  function branchNameEl() {
    return document.querySelector(branchNameSel);
  }

  function changeBranchName(text) {
    branchNameEl().value = text;
    branchNameEl().dispatchEvent(new Event('change'));
  }

  preloadFixtures(fixtureTemplate);

  beforeEach(() => {
    loadFixtures(fixtureTemplate);
    createDropdown();
  });

  it('disable submit when branch name is empty', () => {
    expect(createBranchBtn()).toBeDisabled();
  });

  it('enable submit when branch name is present', () => {
    changeBranchName(branchName);

    expect(createBranchBtn()).not.toBeDisabled();
  });

  it('resets the form when cancel btn is clicked and triggers dropdownback', () => {
    const spyBackEvent = spyOnEvent(backBtnSel, 'click');
    changeBranchName(branchName);

    cancelBtn().click();

    expect(branchNameEl()).toHaveValue('');
    expect(spyBackEvent).toHaveBeenTriggered();
  });

  it('resets the form when back btn is clicked', () => {
    changeBranchName(branchName);

    backBtn().click();

    expect(branchNameEl()).toHaveValue('');
  });

  describe('new branch creation', () => {
    beforeEach(() => {
      changeBranchName(branchName);
    });
    it('sets the new branch name and updates the dropdown', () => {
      spyOn(dropdown, 'setNewBranch');

      createBranchBtn().click();

      expect(dropdown.setNewBranch).toHaveBeenCalledWith(branchName);
    });

    it('resets the form', () => {
      createBranchBtn().click();

      expect(branchNameEl()).toHaveValue('');
    });

    it('is triggered with enter keypress', () => {
      spyOn(dropdown, 'setNewBranch');
      const enterEvent = new Event('keydown');
      enterEvent.which = 13;
      branchNameEl().dispatchEvent(enterEvent);

      expect(dropdown.setNewBranch).toHaveBeenCalledWith(branchName);
    });
  });
});
