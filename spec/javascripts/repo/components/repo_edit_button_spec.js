import Vue from 'vue';
import repoEditButton from '~/repo/components/repo_edit_button.vue';
import RepoStore from '~/repo/stores/repo_store';

describe('RepoEditButton', () => {
  function createComponent() {
    const RepoEditButton = Vue.extend(repoEditButton);

    return new RepoEditButton().$mount();
  }

  it('renders an edit button that toggles the view state', (done) => {
    RepoStore.signedIn = true;
    RepoStore.binary = false;
    RepoStore.canCommit = true;
    RepoStore.changedFiles = [];
    RepoStore.openedFiles = [{}, {}];

    const vm = createComponent();
    const editButton = vm.$el.querySelector('.edit-button');

    expect(editButton.tagName).toEqual('BUTTON');
    expect(editButton.textContent).toMatch('Edit');

    spyOn(vm, 'editCancelClicked').and.callThrough();

    editButton.click();

    Vue.nextTick(() => {
      expect(vm.editCancelClicked).toHaveBeenCalled();
      expect(editButton.textContent).toMatch('Cancel edit');
      done();
    });
  });

  it('does not render if not signedIn', () => {
    RepoStore.signedIn = false;

    const vm = createComponent();

    expect(vm.$el.querySelector('.edit-button')).toBeNull();
  });

  it('renders an fork dialong when clicked if not canCommit', (done) => {
    RepoStore.signedIn = true;
    RepoStore.binary = false;
    RepoStore.canCommit = false;
    RepoStore.changedFiles = [];
    RepoStore.openedFiles = [{}, {}];

    const vm = createComponent();
    vm.$el.querySelector('.edit-button').click();

    Vue.nextTick(() => {
      const popupDialog = vm.$el.querySelector('.popup-dialog');
      const modalFooter = popupDialog.querySelector('.modal-footer');

      expect(popupDialog.querySelector('.modal-title').textContent).toMatch('Create a Fork');
      expect(popupDialog.querySelector('.modal-body').textContent)
        .toMatch('You are not allowed to edit files in this project directly. Please fork this project, make your changes there, and submit a merge request.');
      expect(modalFooter.querySelector('.cancel-button').textContent).toMatch('Cancel');
      expect(modalFooter.querySelector('.primary-button').textContent).toMatch('Create Fork');

      done();
    });
  });

  it('submits a fork form when clicking the primary button of the dialog', (done) => {
    RepoStore.signedIn = true;
    RepoStore.binary = false;
    RepoStore.canCommit = false;
    RepoStore.showForkDialog = true;
    RepoStore.changedFiles = [];
    RepoStore.openedFiles = [{}, {}];

    const paramMeta = document.createElement('meta');
    const tokenMeta = document.createElement('meta');
    paramMeta.name = 'csrf-param';
    tokenMeta.name = 'csrf-token';
    paramMeta.content = 'csrf-param';
    tokenMeta.content = 'csrf-token';
    document.body.appendChild(paramMeta);
    document.body.appendChild(tokenMeta);

    spyOn(HTMLFormElement.prototype, 'submit');

    const vm = createComponent();
    vm.$el.querySelector('.primary-button').click();

    Vue.nextTick(() => {
      const form = document.forms['fork-repo'];
      const input = form.querySelector('input');

      expect(form.method).toEqual('post');
      expect(input.type).toEqual('hidden');
      expect(input.name).toEqual('csrf-param');
      expect(input.value).toEqual('csrf-token');
      expect(HTMLFormElement.prototype.submit).toHaveBeenCalled();

      done();
    });
  });
});
