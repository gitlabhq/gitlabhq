import Vue from 'vue';
import repoTab from '~/repo/components/repo_tab.vue';

describe('RepoTab', () => {
  function createComponent(propsData) {
    const RepoTab = Vue.extend(repoTab);

    return new RepoTab({
      propsData,
    }).$mount();
  }

  it('renders a close link and a name link', () => {
    const tab = {
      url: 'url',
      name: 'name',
    };
    const vm = createComponent({
      tab,
    });
    const close = vm.$el.querySelector('.close');
    const name = vm.$el.querySelector(`a[title="${tab.url}"]`);

    spyOn(vm, 'closeTab');
    spyOn(vm, 'tabClicked');

    expect(close.querySelector('.fa-times')).toBeTruthy();
    expect(name.textContent.trim()).toEqual(tab.name);

    close.click();
    name.click();

    expect(vm.closeTab).toHaveBeenCalledWith(tab);
    expect(vm.tabClicked).toHaveBeenCalledWith(tab);
  });

  it('renders an fa-circle icon if tab is changed', () => {
    const tab = {
      url: 'url',
      name: 'name',
      changed: true,
    };
    const vm = createComponent({
      tab,
    });

    expect(vm.$el.querySelector('.close .fa-circle')).toBeTruthy();
  });

  describe('methods', () => {
    describe('closeTab', () => {
      const vm = jasmine.createSpyObj('vm', ['$emit']);

      it('returns undefined and does not $emit if file is changed', () => {
        const file = { changed: true };
        const returnVal = repoTab.methods.closeTab.call(vm, file);

        expect(returnVal).toBeUndefined();
        expect(vm.$emit).not.toHaveBeenCalled();
      });

      it('$emits tabclosed event with file obj', () => {
        const file = { changed: false };
        repoTab.methods.closeTab.call(vm, file);

        expect(vm.$emit).toHaveBeenCalledWith('tabclosed', file);
      });
    });
  });
});
