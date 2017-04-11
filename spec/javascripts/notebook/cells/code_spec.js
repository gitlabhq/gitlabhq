import Vue from 'vue';
import CodeComponent from '~/notebook/cells/code.vue';
import json from '../../fixtures/notebook/file.json';

const Component = Vue.extend(CodeComponent);

describe('Code component', () => {
  let vm;

  describe('without output', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          cell: json.cells[0],
        },
      });
      vm.$mount();

      setTimeout(() => {
        done();
      });
    });

    it('does not render output prompt', () => {
      expect(vm.$el.querySelectorAll('.prompt').length).toBe(1);
    });
  });

  describe('with output', () => {
    beforeEach((done) => {
      vm = new Component({
        propsData: {
          cell: json.cells[2],
        },
      });
      vm.$mount();

      setTimeout(() => {
        done();
      });
    });

    it('does not render output prompt', () => {
      expect(vm.$el.querySelectorAll('.prompt').length).toBe(2);
    });

    it('renders output cell', () => {
      expect(vm.$el.querySelector('.output')).toBeDefined();
    });
  });
});
