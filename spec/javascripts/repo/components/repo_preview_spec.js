import Vue from 'vue';
import $ from 'jquery';
import repoPreview from '~/repo/components/repo_preview.vue';
import RepoStore from '~/repo/stores/repo_store';
import RepoHelper from '~/repo/helpers/repo_helper';

describe('RepoPreview', () => {
  function createComponent() {
    const RepoPreview = Vue.extend(repoPreview);

    return new RepoPreview().$mount();
  }

  it('renders a div with the activeFile html, binds events and calls highLightIfCurrentLine', () => {
    const activeFile = {
      html: '<p class="file-content">html</p>',
    };
    RepoStore.activeFile = activeFile;

    spyOn($.fn, 'off').and.callThrough();
    spyOn($.fn, 'on').and.callThrough();
    spyOn(RepoHelper, 'highLightIfCurrentLine');

    const vm = createComponent();

    expect(vm.$el.tagName).toEqual('DIV');
    expect(vm.$el.innerHTML).toContain(activeFile.html);
    expect($.fn.off).toHaveBeenCalledWith('click', '.diff-line-num', RepoHelper.diffLineNumClickWrapper);
    expect($.fn.on).toHaveBeenCalledWith('click', '.diff-line-num', RepoHelper.diffLineNumClickWrapper);
    expect(RepoHelper.highLightIfCurrentLine).toHaveBeenCalled();
  });

  it('applies syntax highlight class if js-syntax-highlight class is set', () => {
    const activeFile = {
      html: '<p class="file-content js-syntax-highlight">html</p>',
    };
    RepoStore.activeFile = activeFile;
    window.gon = {
      user_color_scheme: 'user_color_scheme',
    };

    const vm = createComponent();

    expect(vm.$el.querySelector('.js-syntax-highlight').classList.contains(window.gon.user_color_scheme)).toBeTruthy();
  });
});
