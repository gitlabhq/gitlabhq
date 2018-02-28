import Vue from 'vue';
import repoEditor from '~/repo/components/repo_editor.vue';

describe('RepoEditor', () => {
  beforeEach(() => {
    const RepoEditor = Vue.extend(repoEditor);

    this.vm = new RepoEditor().$mount();
  });

  it('renders an ide container', (done) => {
    this.vm.openedFiles = ['idiidid'];
    this.vm.binary = false;

    Vue.nextTick(() => {
      expect(this.vm.shouldHideEditor).toBe(false);
      expect(this.vm.$el.id).toEqual('ide');
      expect(this.vm.$el.tagName).toBe('DIV');
      done();
    });
  });

  describe('when there are no open files', () => {
    it('does not render the ide', (done) => {
      this.vm.openedFiles = [];

      Vue.nextTick(() => {
        expect(this.vm.shouldHideEditor).toBe(true);
        expect(this.vm.$el.tagName).not.toBeDefined();
        done();
      });
    });
  });

  describe('when open file is binary and not raw', () => {
    it('does not render the IDE', (done) => {
      this.vm.binary = true;
      this.vm.activeFile = {
        raw: false,
      };

      Vue.nextTick(() => {
        expect(this.vm.shouldHideEditor).toBe(true);
        expect(this.vm.$el.tagName).not.toBeDefined();
        done();
      });
    });
  });
});
