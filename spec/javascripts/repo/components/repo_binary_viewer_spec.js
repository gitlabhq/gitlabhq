import Vue from 'vue';
import Store from '~/repo/stores/repo_store';
import repoBinaryViewer from '~/repo/components/repo_binary_viewer.vue';

describe('RepoBinaryViewer', () => {
  function createComponent() {
    const RepoBinaryViewer = Vue.extend(repoBinaryViewer);

    return new RepoBinaryViewer().$mount();
  }

  function createActiveFile(type, activeFile = {}) {
    const file = activeFile;

    switch (type) {
      case 'svg':
      case 'png':
        file.name = 'name';
        break;
      case 'md':
        file.html = 'html';
        break;
      default:
        break;
    }

    return file;
  }

  function setActiveBinary(type) {
    const binaryTypes = {};
    binaryTypes[type] = true;

    const activeFile = createActiveFile(type);

    const uri = 'uri';
    Store.binary = true;
    Store.binaryTypes = binaryTypes;
    Store.activeFile = activeFile;
    Store.pngBlobWithDataURI = uri;

    return {
      activeFile,
      uri,
    };
  }

  function assertBinaryImg(img, activeFile, uri) {
    expect(img.src).toMatch(`/${uri}`);
    expect(img.alt).toEqual(activeFile.name);
  }

  it('renders an img if its png', () => {
    const { activeFile, uri } = setActiveBinary('png');
    const vm = createComponent();
    const img = vm.$el.querySelector(':scope > img');

    assertBinaryImg(img, activeFile, uri);
  });

  it('renders an img if its svg', () => {
    const { activeFile, uri } = setActiveBinary('svg');
    const vm = createComponent();
    const img = vm.$el.querySelector(':scope > img');

    assertBinaryImg(img, activeFile, uri);
  });

  it('renders an div with content if its markdown', () => {
    const { activeFile } = setActiveBinary('md');
    const vm = createComponent();

    expect(vm.$el.querySelector(':scope > div').innerHTML).toEqual(activeFile.html);
  });

  it('renders no preview message if its unknown', () => {
    setActiveBinary('unknown');
    const vm = createComponent();

    expect(vm.$el.querySelector('.binary-unknown').textContent).toMatch('Binary file. No preview available.');
  });

  it('does not render if no binary', () => {
    Store.binary = false;
    const vm = createComponent();

    expect(vm.$el.innerHTML).toBeFalsy();
  });
});
