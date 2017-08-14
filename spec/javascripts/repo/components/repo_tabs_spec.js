import Vue from 'vue';
import RepoStore from '~/repo/stores/repo_store';
import repoTabs from '~/repo/components/repo_tabs.vue';

describe('RepoTabs', () => {
  const openedFiles = [{
    id: 0,
    active: true,
  }, {
    id: 1,
  }];

  function createComponent() {
    const RepoTabs = Vue.extend(repoTabs);

    return new RepoTabs().$mount();
  }

  it('renders a list of tabs', () => {
    RepoStore.openedFiles = openedFiles;

    const vm = createComponent();
    const tabs = [...vm.$el.querySelectorAll(':scope > li')];

    expect(vm.$el.id).toEqual('tabs');
    expect(tabs.length).toEqual(3);
    expect(tabs[0].classList.contains('active')).toBeTruthy();
    expect(tabs[1].classList.contains('active')).toBeFalsy();
    expect(tabs[2].classList.contains('tabs-divider')).toBeTruthy();
  });

  it('does not render a tabs list if not isMini', () => {
    RepoStore.openedFiles = [];

    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });

  describe('methods', () => {
    describe('xClicked', () => {
      it('calls removeFromOpenedFiles with file obj', () => {
        const file = {};

        spyOn(RepoStore, 'removeFromOpenedFiles');

        repoTabs.methods.xClicked(file);

        expect(RepoStore.removeFromOpenedFiles).toHaveBeenCalledWith(file);
      });
    });
  });
});
