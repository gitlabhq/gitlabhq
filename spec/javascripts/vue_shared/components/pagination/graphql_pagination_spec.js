import { shallowMount, createLocalVue } from '@vue/test-utils';
import GraphqlPagination from '~/vue_shared/components/pagination/graphql_pagination.vue';

const localVue = createLocalVue();

describe('Graphql Pagination component', () => {
  let wrapper;
  function factory({ hasNextPage = true, hasPreviousPage = true }) {
    wrapper = shallowMount(localVue.extend(GraphqlPagination), {
      propsData: {
        hasNextPage,
        hasPreviousPage,
      },
      localVue,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without previous page', () => {
    beforeEach(() => {
      factory({ hasPreviousPage: false });
    });

    it('renders disabled previous button', () => {
      expect(wrapper.find('.js-prev-btn').attributes().disabled).toEqual('true');
    });
  });

  describe('with previous page', () => {
    beforeEach(() => {
      factory({ hasPreviousPage: true });
    });

    it('renders enabled previous button', () => {
      expect(wrapper.find('.js-prev-btn').attributes().disabled).toEqual(undefined);
    });

    it('emits previousClicked on click', () => {
      wrapper.find('.js-prev-btn').vm.$emit('click');

      expect(wrapper.emitted().previousClicked.length).toBe(1);
    });
  });

  describe('without next page', () => {
    beforeEach(() => {
      factory({ hasNextPage: false });
    });

    it('renders disabled next button', () => {
      expect(wrapper.find('.js-next-btn').attributes().disabled).toEqual('true');
    });
  });

  describe('with next page', () => {
    beforeEach(() => {
      factory({ hasNextPage: true });
    });

    it('renders enabled next button', () => {
      expect(wrapper.find('.js-next-btn').attributes().disabled).toEqual(undefined);
    });

    it('emits nextClicked on click', () => {
      wrapper.find('.js-next-btn').vm.$emit('click');

      expect(wrapper.emitted().nextClicked.length).toBe(1);
    });
  });
});
