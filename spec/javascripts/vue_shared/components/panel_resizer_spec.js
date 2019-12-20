import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import panelResizer from '~/vue_shared/components/panel_resizer.vue';

describe('Panel Resizer component', () => {
  let vm;
  let PanelResizer;

  const triggerEvent = (eventName, el = vm.$el, clientX = 0) => {
    const event = document.createEvent('MouseEvents');
    event.initMouseEvent(
      eventName,
      true,
      true,
      window,
      1,
      clientX,
      0,
      clientX,
      0,
      false,
      false,
      false,
      false,
      0,
      null,
    );

    el.dispatchEvent(event);
  };

  beforeEach(() => {
    PanelResizer = Vue.extend(panelResizer);
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render a div element with the correct classes and styles', () => {
    vm = mountComponent(PanelResizer, {
      startSize: 100,
      side: 'left',
    });

    expect(vm.$el.tagName).toEqual('DIV');
    expect(vm.$el.getAttribute('class')).toBe(
      'position-absolute position-top-0 position-bottom-0 drag-handle position-left-0',
    );

    expect(vm.$el.getAttribute('style')).toBe('cursor: ew-resize;');
  });

  it('should render a div element with the correct classes for a right side panel', () => {
    vm = mountComponent(PanelResizer, {
      startSize: 100,
      side: 'right',
    });

    expect(vm.$el.tagName).toEqual('DIV');
    expect(vm.$el.getAttribute('class')).toBe(
      'position-absolute position-top-0 position-bottom-0 drag-handle position-right-0',
    );
  });

  it('drag the resizer', () => {
    vm = mountComponent(PanelResizer, {
      startSize: 100,
      side: 'left',
    });

    spyOn(vm, '$emit');
    triggerEvent('mousedown', vm.$el);
    triggerEvent('mousemove', document);
    triggerEvent('mouseup', document);

    expect(vm.$emit.calls.allArgs()).toEqual([
      ['resize-start', 100],
      ['update:size', 100],
      ['resize-end', 100],
    ]);

    expect(vm.size).toBe(100);
  });
});
