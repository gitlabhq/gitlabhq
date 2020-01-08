import Vue from 'vue';
import headerComponent from '~/pipelines/components/header_component.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipeline details header', () => {
  let HeaderComponent;
  let vm;
  let props;

  beforeEach(() => {
    HeaderComponent = Vue.extend(headerComponent);

    const threeWeeksAgo = new Date();
    threeWeeksAgo.setDate(threeWeeksAgo.getDate() - 21);

    props = {
      pipeline: {
        details: {
          status: {
            group: 'failed',
            icon: 'status_failed',
            label: 'failed',
            text: 'failed',
            details_path: 'path',
          },
        },
        id: 123,
        created_at: threeWeeksAgo.toISOString(),
        user: {
          web_url: 'path',
          name: 'Foo',
          username: 'foobar',
          email: 'foo@bar.com',
          avatar_url: 'link',
        },
        retry_path: 'path',
        delete_path: 'path',
      },
      isLoading: false,
    };

    vm = new HeaderComponent({ propsData: props }).$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('should render provided pipeline info', () => {
    expect(
      vm.$el
        .querySelector('.header-main-content')
        .textContent.replace(/\s+/g, ' ')
        .trim(),
    ).toContain('failed Pipeline #123 triggered 3 weeks ago by Foo');
  });

  describe('action buttons', () => {
    it('should call postAction when retry button action is clicked', done => {
      eventHub.$on('headerPostAction', action => {
        expect(action.path).toEqual('path');
        done();
      });

      vm.$el.querySelector('.js-retry-button').click();
    });

    it('should fire modal event when delete button action is clicked', done => {
      vm.$root.$on('bv::modal::show', action => {
        expect(action.componentId).toEqual('pipeline-delete-modal');
        done();
      });

      vm.$el.querySelector('.js-btn-delete-pipeline').click();
    });
  });
});
