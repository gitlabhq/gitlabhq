import Vue from 'vue';
import store from '~/ide/stores';
import repoEditButton from '~/ide/components/repo_edit_button.vue';
import { file, resetStore } from '../helpers';

describe('RepoEditButton', () => {
  let vm;

  beforeEach(() => {
    const f = file();
    const RepoEditButton = Vue.extend(repoEditButton);

    vm = new RepoEditButton({
      store,
    });

    f.active = true;
    vm.$store.dispatch('setInitialData', {
      canCommit: true,
      onTopOfBranch: true,
    });
    vm.$store.state.openFiles.push(f);
  });

  afterEach(() => {
    vm.$destroy();

    resetStore(vm.$store);
  });

  it('renders an edit button', () => {
    vm.$mount();

    expect(vm.$el.querySelector('.btn')).not.toBeNull();
    expect(vm.$el.querySelector('.btn').textContent.trim()).toBe('Cancel edit');
  });

  it('renders edit button with cancel text', () => {
    vm.$store.state.editMode = true;

    vm.$mount();

    expect(vm.$el.querySelector('.btn')).not.toBeNull();
    expect(vm.$el.querySelector('.btn').textContent.trim()).toBe('Cancel edit');
  });

  it('toggles edit mode on click', (done) => {
    vm.$mount();

    vm.$el.querySelector('.btn').click();

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.btn').textContent.trim()).toBe('Edit');

      done();
    });
  });
});
