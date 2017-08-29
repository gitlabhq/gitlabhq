import Vue from 'vue';
import repoFileFooter from '~/repo/components/repo_file_footer.vue';

describe('RepoFileFooter', () => {
  const RepoFileFooter = Vue.extend(repoFileFooter);

  describe('render', () => {
    let component;
    const propsData = {
      filePath: 'test/filepath.txt',
      mimeType: 'text/plain',
    };

    beforeEach(() => {
      component = new RepoFileFooter({
        propsData,
      }).$mount();
    });

    it('renders file path', () => {
      const branchIcon = component.$el.querySelector('.fa-code-fork');
      expect(branchIcon.nextElementSibling.innerText).toEqual(propsData.filePath);
    });

    it('renders mime type', () => {
      const mimeType = component.$el.querySelector('.pull-right');
      expect(mimeType.innerText).toEqual(propsData.mimeType);
    });
  });
});
