import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import MrWidgetAuthor from '~/vue_merge_request_widget/components/mr_widget_author.vue';

describe('MrWidgetAuthor', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(MrWidgetAuthor);

    vm = mountComponent(Component, {
      author: {
        name: 'Administrator',
        username: 'root',
        webUrl: 'http://localhost:3000/root',
        avatarUrl:
          'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      },
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders link with the author web url', () => {
    expect(vm.$el.getAttribute('href')).toEqual('http://localhost:3000/root');
  });

  it('renders image with avatar url', () => {
    expect(vm.$el.querySelector('img').getAttribute('src')).toEqual(
      'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
    );
  });

  it('renders author name', () => {
    expect(vm.$el.textContent.trim()).toEqual('Administrator');
  });
});
