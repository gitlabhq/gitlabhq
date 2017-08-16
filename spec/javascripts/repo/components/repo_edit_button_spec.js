import Vue from 'vue';
import repoEditButton from '~/repo/components/repo_edit_button.vue';
import RepoStore from '~/repo/stores/repo_store';

describe('RepoEditButton', () => {
  function createComponent() {
    const RepoEditButton = Vue.extend(repoEditButton);

    return new RepoEditButton().$mount();
  }

  it('renders an edit button that toggles the view state', (done) => {
    RepoStore.isCommitable = true;
    RepoStore.changedFiles = [];
    RepoStore.binary = false;
    RepoStore.openedFiles = [{}, {}];

    const vm = createComponent();

    expect(vm.$el.tagName).toEqual('BUTTON');
    expect(vm.$el.textContent).toMatch('Edit');

    spyOn(vm, 'editCancelClicked').and.callThrough();
    spyOn(vm, 'toggleProjectRefsForm');

    vm.$el.click();

    Vue.nextTick(() => {
      expect(vm.editCancelClicked).toHaveBeenCalled();
      expect(vm.toggleProjectRefsForm).toHaveBeenCalled();
      expect(vm.$el.textContent).toMatch('Cancel edit');
      done();
    });
  });

  it('does not render if not isCommitable', () => {
    RepoStore.isCommitable = false;

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeUndefined();
  });

  describe('methods', () => {
    describe('editCancelClicked', () => {
      it('sets dialog to open when there are changedFiles');

      it('toggles editMode and calls toggleBlobView');
    });
  });
});
