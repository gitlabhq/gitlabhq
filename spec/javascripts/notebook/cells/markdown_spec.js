import Vue from 'vue';
import MarkdownComponent from '~/notebook/cells/markdown.vue';
import katex from 'katex';

const Component = Vue.extend(MarkdownComponent);

window.katex = katex;

describe('Markdown component', () => {
  let vm;
  let cell;
  let json;

  beforeEach((done) => {
    json = getJSONFixture('blob/notebook/basic.json');

    cell = json.cells[1];

    vm = new Component({
      propsData: {
        cell,
      },
    });
    vm.$mount();

    setTimeout(() => {
      done();
    });
  });

  it('does not render promot', () => {
    expect(vm.$el.querySelector('.prompt span')).toBeNull();
  });

  it('does not render the markdown text', () => {
    expect(
      vm.$el.querySelector('.markdown').innerHTML.trim(),
    ).not.toEqual(cell.source.join(''));
  });

  it('renders the markdown HTML', () => {
    expect(vm.$el.querySelector('.markdown h1')).not.toBeNull();
  });

  it('sanitizes output', (done) => {
    Object.assign(cell, {
      source: ['[XSS](data:text/html;base64,PHNjcmlwdD5hbGVydChkb2N1bWVudC5kb21haW4pPC9zY3JpcHQ+Cg==)\n'],
    });

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('a')).toBeNull();

      done();
    });
  });

  describe('katex', () => {
    beforeEach(() => {
      json = getJSONFixture('blob/notebook/math.json');
    });

    it('renders multi-line katex', (done) => {
      vm = new Component({
        propsData: {
          cell: json.cells[0],
        },
      }).$mount();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.katex'),
        ).not.toBeNull();

        done();
      });
    });

    it('renders inline katex', (done) => {
      vm = new Component({
        propsData: {
          cell: json.cells[1],
        },
      }).$mount();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('p:first-child .katex'),
        ).not.toBeNull();

        done();
      });
    });

    it('renders multiple inline katex', (done) => {
      vm = new Component({
        propsData: {
          cell: json.cells[1],
        },
      }).$mount();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelectorAll('p:nth-child(2) .katex').length,
        ).toBe(4);

        done();
      });
    });
  });
});
