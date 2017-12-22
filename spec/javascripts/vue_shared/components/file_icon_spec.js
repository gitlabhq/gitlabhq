import Vue from 'vue';
import fileIcon from '~/vue_shared/components/file_icon.vue';

describe('File Icon component', () => {
  let FileIcon;
  beforeEach(() => {
    FileIcon = Vue.extend(fileIcon);
  });

  it('should render a span element with an svg', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'test.js',
      },
    }).$mount();

    expect(component.$el.tagName).toEqual('SPAN');
    expect(component.$el.querySelector('span > svg')).toBeDefined();
  });

  it('should render a javascript icon based on file ending', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'test.js',
      },
    }).$mount();

    expect(component.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#javascript`);
  });

  it('should render a image icon based on file ending', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'test.png',
      },
    }).$mount();

    expect(component.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#image`);
  });

  it('should render a webpack icon based on file namer', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'webpack.js',
      },
    }).$mount();

    expect(component.$el.firstChild.firstChild.getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#webpack`);
  });

  it('should render a standard folder icon', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'js',
        folder: true,
      },
    }).$mount();

    expect(component.$el.querySelector('span > svg > use').getAttribute('xlink:href')).toBe(`${gon.sprite_file_icons}#folder`);
  });

  it('should render a loading icon', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'test.js',
        loading: true,
      },
    }).$mount();

    expect(
      component.$el.querySelector('i').getAttribute('class'),
    ).toEqual('fa fa-spin fa-spinner fa-1x');
  });

  it('should add a special class and a size class', () => {
    const component = new FileIcon({
      propsData: {
        fileName: 'test.js',
        cssClasses: 'extraclasses',
        size: 120,
      },
    }).$mount();

    const classList = component.$el.firstChild.classList;
    const containsSizeClass = classList.contains('s120');
    const containsCustomClass = classList.contains('extraclasses');
    expect(containsSizeClass).toBe(true);
    expect(containsCustomClass).toBe(true);
  });
});
