import Vue from 'vue';
import { file } from 'spec/ide/helpers';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('File row component', () => {
  let vm;

  function createComponent(propsData) {
    const FileRowComponent = Vue.extend(FileRow);

    vm = mountComponent(FileRowComponent, propsData);
  }

  afterEach(() => {
    vm.$destroy();
  });

  const findNewDropdown = () => vm.$el.querySelector('.ide-new-btn .dropdown');
  const findNewDropdownButton = () => vm.$el.querySelector('.ide-new-btn .dropdown button');
  const findFileRow = () => vm.$el.querySelector('.file-row');

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

  it('renders header for file', () => {
    createComponent({
      file: {
        isHeader: true,
        path: 'app/assets',
        tree: [],
      },
      level: 0,
    });

    expect(vm.$el.querySelector('.js-file-row-header')).not.toBe(null);
  });

  describe('new dropdown', () => {
    beforeEach(() => {
      createComponent({
        file: file('t5'),
        level: 1,
        extraComponent: FileRowExtra,
      });
    });

    it('renders in extra component', () => {
      expect(findNewDropdown()).not.toBe(null);
    });

    it('is hidden at start', () => {
      expect(findNewDropdown()).not.toHaveClass('show');
    });

    it('is opened when button is clicked', done => {
      expect(vm.dropdownOpen).toBe(false);
      findNewDropdownButton().dispatchEvent(new Event('click'));

      vm.$nextTick()
        .then(() => {
          expect(vm.dropdownOpen).toBe(true);
          expect(findNewDropdown()).toHaveClass('show');
        })
        .then(done)
        .catch(done.fail);
    });

    describe('when opened', () => {
      beforeEach(() => {
        vm.dropdownOpen = true;
      });

      it('stays open when button triggers mouseout', () => {
        findNewDropdownButton().dispatchEvent(new Event('mouseout'));

        expect(vm.dropdownOpen).toBe(true);
      });

      it('stays open when button triggers mouseleave', () => {
        findNewDropdownButton().dispatchEvent(new Event('mouseleave'));

        expect(vm.dropdownOpen).toBe(true);
      });

      it('closes when row triggers mouseleave', () => {
        findFileRow().dispatchEvent(new Event('mouseleave'));

        expect(vm.dropdownOpen).toBe(false);
      });
    });
  });
});
