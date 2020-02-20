import Vue from 'vue';
import headerComponent from '~/pipelines/components/header_component.vue';
import eventHub from '~/pipelines/event_hub';

describe('Pipeline details header', () => {
  let HeaderComponent;
  let vm;
  let props;

  beforeEach(() => {
    spyOn(eventHub, '$emit');
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
        retry_path: 'retry',
        cancel_path: 'cancel',
        delete_path: 'delete',
      },
      isLoading: false,
    };

    vm = new HeaderComponent({ propsData: props }).$mount();
  });

  afterEach(() => {
    eventHub.$off();
    vm.$destroy();
  });

  const findDeleteModal = () => document.getElementById(headerComponent.DELETE_MODAL_ID);
  const findDeleteModalSubmit = () =>
    [...findDeleteModal().querySelectorAll('.btn')].find(x => x.textContent === 'Delete pipeline');

  it('should render provided pipeline info', () => {
    expect(
      vm.$el
        .querySelector('.header-main-content')
        .textContent.replace(/\s+/g, ' ')
        .trim(),
    ).toContain('failed Pipeline #123 triggered 3 weeks ago by Foo');
  });

  describe('action buttons', () => {
    it('should not trigger eventHub when nothing happens', () => {
      expect(eventHub.$emit).not.toHaveBeenCalled();
    });

    it('should call postAction when retry button action is clicked', () => {
      vm.$el.querySelector('.js-retry-button').click();

      expect(eventHub.$emit).toHaveBeenCalledWith('headerPostAction', 'retry');
    });

    it('should call postAction when cancel button action is clicked', () => {
      vm.$el.querySelector('.js-btn-cancel-pipeline').click();

      expect(eventHub.$emit).toHaveBeenCalledWith('headerPostAction', 'cancel');
    });

    it('does not show delete modal', () => {
      expect(findDeleteModal()).not.toBeVisible();
    });

    describe('when delete button action is clicked', () => {
      beforeEach(done => {
        vm.$el.querySelector('.js-btn-delete-pipeline').click();

        // Modal needs two ticks to show
        vm.$nextTick()
          .then(() => vm.$nextTick())
          .then(done)
          .catch(done.fail);
      });

      it('should show delete modal', () => {
        expect(findDeleteModal()).toBeVisible();
      });

      it('should call delete when modal is submitted', () => {
        findDeleteModalSubmit().click();

        expect(eventHub.$emit).toHaveBeenCalledWith('headerDeleteAction', 'delete');
      });
    });
  });
});
