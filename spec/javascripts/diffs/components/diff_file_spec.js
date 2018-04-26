import Vue from 'vue';
import DiffFileComponent from '~/diffs/components/diff_file.vue';
import store from '~/mr_notes/stores';
import { createComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import diffFileMockData from '../mock_data/diff_file';

describe('DiffFile', () => {
  let component;
  const getDiffFileMock = () => Object.assign({}, diffFileMockData);

  beforeEach(() => {
    component = createComponentWithStore(Vue.extend(DiffFileComponent), store, {
      file: getDiffFileMock(),
    }).$mount(document.createElement('div'));
  });

  describe('template', () => {
    it('should render component with file header, file content components', () => {
      const el = component.$el;
      const { fileHash, filePath } = diffFileMockData;

      expect(el.id).toEqual(fileHash);
      expect(el.classList.contains('diff-file')).toEqual(true);
      expect(el.querySelector('.js-file-title')).toBeDefined();
      expect(el.querySelector('.file-title-name').innerText.indexOf(filePath) > -1).toEqual(true);
      expect(el.querySelector('.js-syntax-highlight')).toBeDefined();
      expect(el.querySelectorAll('.line_content').length > 5).toEqual(true);
    });
  });
});
