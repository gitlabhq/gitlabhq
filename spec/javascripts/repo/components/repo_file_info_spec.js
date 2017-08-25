import Vue from 'vue';
import repoFileInfo from '~/repo/components/repo_file_info.vue';

describe('RepoFileInfo', () => {
  const RepoFileInfo = Vue.extend(repoFileInfo);

  describe('render', () => {
    let component;

    describe('all data loaded', () => {
      const loadedPropsData = {
        branchName: 'master',
        lastCommitHash: '1a2b3c4d5e6f',
        lastCommitUrl: 'gitlab-org/gitlab-ce/1a2b3c4d5e6f',
        mimeType: 'text/plain',
      };

      beforeEach(() => {
        component = new RepoFileInfo({
          propsData: loadedPropsData,
        }).$mount();
      });

      it('renders branch name after branch icon', () => {
        const branchIcon = component.$el.querySelector('.fa-code-fork');
        expect(branchIcon.nextElementSibling.innerText).toEqual(loadedPropsData.branchName);
      });

      it('renders mime type on the right', () => {
        const mimeType = component.$el.querySelector('.pull-right');
        expect(mimeType.innerText).toEqual(loadedPropsData.mimeType);
      });

      it('renders last commit url', () => {
        const url = component.$el.querySelector('a');
        expect(url.getAttribute('href')).toEqual(loadedPropsData.lastCommitUrl);
      });

      it('renders the url text as the first 8 characters of the commit hash', () => {
        const url = component.$el.querySelector('a');
        expect(url.innerText.trim()).toEqual(loadedPropsData.lastCommitHash.slice(0, 8));
      });

      it('does not render spinner', () => {
        const spinner = component.$el.querySelector('.fa-spinner');
        expect(spinner).toBeFalsy();
      });
    });

    describe('data is loading', () => {
      const loadingPropsData = {
        branchName: 'master',
        lastCommitHash: '',
        lastCommitUrl: '',
        mimeType: 'text/plain',
      };

      beforeEach(() => {
        component = new RepoFileInfo({
          propsData: loadingPropsData,
        }).$mount();
      });

      it('renders loading spinner', () => {
        const spinner = component.$el.querySelector('.fa-spinner');
        expect(spinner).toBeTruthy();
      });

      it('does not render last commit url', () => {
        const url = component.$el.querySelector('a');
        expect(url).toBeFalsy();
      });
    });
  });
});
