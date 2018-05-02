import Vue from 'vue';
import $ from 'jquery';
import headerComponent from '~/vue_shared/components/markdown/header.vue';

describe('Markdown field header component', () => {
  let vm;

  beforeEach(done => {
    const Component = Vue.extend(headerComponent);

    vm = new Component({
      propsData: {
        previewMarkdown: false,
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('renders markdown buttons', () => {
    expect(vm.$el.querySelectorAll('.js-md').length).toBe(7);
  });

  it('renders `write` link as active when previewMarkdown is false', () => {
    expect(vm.$el.querySelector('li:nth-child(1)').classList.contains('active')).toBeTruthy();
  });

  it('renders `preview` link as active when previewMarkdown is true', done => {
    vm.previewMarkdown = true;

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('li:nth-child(2)').classList.contains('active')).toBeTruthy();

      done();
    });
  });

  it('emits toggle markdown event when clicking preview', () => {
    spyOn(vm, '$emit');

    vm.$el.querySelector('.js-preview-link').click();

    expect(vm.$emit).toHaveBeenCalledWith('preview-markdown');

    vm.$el.querySelector('.js-write-link').click();

    expect(vm.$emit).toHaveBeenCalledWith('write-markdown');
  });

  it('does not emit toggle markdown event when triggered from another form', () => {
    spyOn(vm, '$emit');

    $(document).triggerHandler('markdown-preview:show', [
      $('<form><textarea class="markdown-area"></textarea></textarea></form>'),
    ]);

    expect(vm.$emit).not.toHaveBeenCalled();
  });

  it('blurs preview link after click', done => {
    const link = vm.$el.querySelector('li:nth-child(2) a');
    spyOn(HTMLElement.prototype, 'blur');

    link.click();

    setTimeout(() => {
      expect(link.blur).toHaveBeenCalled();

      done();
    });
  });
});
