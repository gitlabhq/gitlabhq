import Vue from 'vue';
import MarkdownComponent from '~/notebook/cells/markdown.vue';
import json from '../../fixtures/notebook/file.json';

const cell = json.cells[1];
const Component = Vue.extend(MarkdownComponent);

describe('Markdown component', () => {
  let vm;

  beforeEach((done) => {
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
});
