import Vue from 'vue';
import fileIcon from '~/vue_shared/components/file_icon.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('File Icon component', () => {
  let vm;
  let FileIcon;

  beforeEach(() => {
    FileIcon = Vue.extend(fileIcon);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render a span element with an svg', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'test.js',
    });

    expect(vm.$el.tagName).toEqual('SPAN');
    expect(vm.$el.querySelector('span > svg')).toBeDefined();
  });

  it('should render a javascript icon based on file ending', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'test.js',
    });

    expect(vm.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#javascript`);
  });

  it('should render a image icon based on file ending', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'test.png',
    });

    expect(vm.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#image`);
  });

  it('should render a webpack icon based on file namer', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'webpack.js',
    });

    expect(vm.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#webpack`);
  });

  it('should render a standard folder icon', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'js',
      folder: true,
    });

    expect(vm.$el.querySelector('span > svg > use').getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#folder`);
  });

  it('should render a loading icon', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'test.js',
      loading: true,
    });

    expect(
      vm.$el.querySelector('i').getAttribute('class'),
    ).toEqual('fa fa-spin fa-spinner fa-1x');
  });

  it('should add a special class and a size class', () => {
    vm = mountComponent(FileIcon, {
      fileName: 'test.js',
      cssClasses: 'extraclasses',
      size: 120,
    });

    const classList = vm.$el.firstChild.classList;
    const containsSizeClass = classList.contains('s120');
    const containsCustomClass = classList.contains('extraclasses');
    expect(containsSizeClass).toBe(true);
    expect(containsCustomClass).toBe(true);
  });
});
