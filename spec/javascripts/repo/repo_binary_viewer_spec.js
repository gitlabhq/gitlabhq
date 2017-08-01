import Vue from 'vue';
import Store from '~/repo/repo_store';
import repoBinaryViewer from '~/repo/repo_binary_viewer.vue';

describe('RepoBinaryViewer', () => {
  function createComponent() {
    const RepoBinaryViewer = Vue.extend(repoBinaryViewer);

    return new RepoBinaryViewer().$mount();
  }

  it('renders an img if its png', () => {
    const binaryTypes = {
      png: true,
    };
    const activeFile = {
      name: 'name',
    };
    const uri = 'uri';
    Store.binary = true;
    Store.binaryTypes = binaryTypes;
    Store.activeFile = activeFile;
    Store.pngBlobWithDataURI = uri;
    const vm = createComponent();
    const img = vm.$el.querySelector(':scope > img');

    expect(img.src).toMatch(`/${uri}`);
    expect(img.alt).toEqual(activeFile.name);
  });

  it('renders an div with content if its markdown', () => {
    const binaryTypes = {
      md: true,
    };
    const activeFile = {
      html: 'markdown',
    };
    Store.binary = true;
    Store.binaryTypes = binaryTypes;
    Store.activeFile = activeFile;
    const vm = createComponent();

    expect(vm.$el.querySelector(':scope > div').innerHTML).toEqual(activeFile.html);
  });

  it('does not render if no binary', () => {
    Store.binary = false;
    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });
});
