import Vue from 'vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import { file } from 'spec/ide/helpers';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('RepoFile', () => {
  let vm;

  function createComponent(propsData) {
    const FileRowComponent = Vue.extend(FileRow);

    vm = mountComponent(FileRowComponent, propsData);
  }

  afterEach(() => {
    vm.$destroy();
  });

  it('renders name', () => {
    createComponent({
      file: file('t4'),
      level: 0,
    });

    const name = vm.$el.querySelector('.file-row-name');

    expect(name.textContent.trim()).toEqual(vm.file.name);
  });

  it('emits toggleTreeOpen on click', () => {
    createComponent({
      file: {
        ...file('t3'),
        type: 'tree',
      },
      level: 0,
    });
    spyOn(vm, '$emit').and.stub();

    vm.$el.querySelector('.file-row').click();

    expect(vm.$emit).toHaveBeenCalledWith('toggleTreeOpen', vm.file.path);
  });

  it('calls scrollIntoView if made active', done => {
    createComponent({
      file: {
        ...file(),
        type: 'blob',
        active: false,
      },
      level: 0,
    });

    spyOn(vm, 'scrollIntoView').and.stub();

    vm.file.active = true;

    vm.$nextTick(() => {
      expect(vm.scrollIntoView).toHaveBeenCalled();

      done();
    });
  });

  it('indents row based on level', () => {
    createComponent({
      file: file('t4'),
      level: 2,
    });

    expect(vm.$el.querySelector('.file-row-name').style.marginLeft).toBe('32px');
  });

  describe('outputText', () => {
    beforeEach(done => {
      createComponent({
        file: {
          ...file(),
          path: 'app/assets/index.js',
        },
        level: 0,
      });

      vm.displayTextKey = 'path';

      vm.$nextTick(done);
    });

    it('returns text if truncateStart is 0', done => {
      vm.truncateStart = 0;

      vm.$nextTick(() => {
        expect(vm.outputText).toBe('app/assets/index.js');

        done();
      });
    });

    it('returns text truncated at start', done => {
      vm.truncateStart = 5;

      vm.$nextTick(() => {
        expect(vm.outputText).toBe('...ssets/index.js');

        done();
      });
    });
  });
});
