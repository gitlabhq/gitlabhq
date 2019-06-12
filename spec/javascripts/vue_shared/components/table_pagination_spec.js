import Vue from 'vue';
import paginationComp from '~/vue_shared/components/pagination/table_pagination.vue';

describe('Pagination component', () => {
  let component;
  let PaginationComponent;
  let spy;
  let mountComponent;

  beforeEach(() => {
    spy = jasmine.createSpy('spy');
    PaginationComponent = Vue.extend(paginationComp);

    mountComponent = function(props) {
      return new PaginationComponent({
        propsData: props,
      }).$mount();
    };
  });

  describe('render', () => {
    it('should not render anything', () => {
      component = mountComponent({
        pageInfo: {
          nextPage: NaN,
          page: 1,
          perPage: 20,
          previousPage: NaN,
          total: 15,
          totalPages: 1,
        },
        change: spy,
      });

      expect(component.$el.childNodes.length).toEqual(0);
    });

    describe('prev button', () => {
      it('should be disabled and non clickable', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 2,
            page: 1,
            perPage: 20,
            previousPage: NaN,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        expect(
          component.$el.querySelector('.js-previous-button').classList.contains('disabled'),
        ).toEqual(true);

        component.$el.querySelector('.js-previous-button .page-link').click();

        expect(spy).not.toHaveBeenCalled();
      });

      it('should be disabled and non clickable when total and totalPages are NaN', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 2,
            page: 1,
            perPage: 20,
            previousPage: NaN,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        expect(
          component.$el.querySelector('.js-previous-button').classList.contains('disabled'),
        ).toEqual(true);

        component.$el.querySelector('.js-previous-button .page-link').click();

        expect(spy).not.toHaveBeenCalled();
      });

      it('should be enabled and clickable', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        component.$el.querySelector('.js-previous-button .page-link').click();

        expect(spy).toHaveBeenCalledWith(1);
      });

      it('should be enabled and clickable when total and totalPages are NaN', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        component.$el.querySelector('.js-previous-button .page-link').click();

        expect(spy).toHaveBeenCalledWith(1);
      });
    });

    describe('first button', () => {
      it('should call the change callback with the first page', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        const button = component.$el.querySelector('.js-first-button .page-link');

        expect(button.textContent.trim()).toEqual('« First');

        button.click();

        expect(spy).toHaveBeenCalledWith(1);
      });

      it('should call the change callback with the first page when total and totalPages are NaN', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        const button = component.$el.querySelector('.js-first-button .page-link');

        expect(button.textContent.trim()).toEqual('« First');

        button.click();

        expect(spy).toHaveBeenCalledWith(1);
      });
    });

    describe('last button', () => {
      it('should call the change callback with the last page', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        const button = component.$el.querySelector('.js-last-button .page-link');

        expect(button.textContent.trim()).toEqual('Last »');

        button.click();

        expect(spy).toHaveBeenCalledWith(5);
      });

      it('should not render', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 3,
            page: 2,
            perPage: 20,
            previousPage: 1,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        expect(component.$el.querySelector('.js-last-button .page-link')).toBeNull();
      });
    });

    describe('next button', () => {
      it('should be disabled and non clickable', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: NaN,
            page: 5,
            perPage: 20,
            previousPage: 4,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        expect(component.$el.querySelector('.js-next-button').textContent.trim()).toEqual('Next');

        component.$el.querySelector('.js-next-button .page-link').click();

        expect(spy).not.toHaveBeenCalled();
      });

      it('should be disabled and non clickable when total and totalPages are NaN', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: NaN,
            page: 5,
            perPage: 20,
            previousPage: 4,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        expect(component.$el.querySelector('.js-next-button').textContent.trim()).toEqual('Next');

        component.$el.querySelector('.js-next-button .page-link').click();

        expect(spy).not.toHaveBeenCalled();
      });

      it('should be enabled and clickable', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        component.$el.querySelector('.js-next-button .page-link').click();

        expect(spy).toHaveBeenCalledWith(4);
      });

      it('should be enabled and clickable when total and totalPages are NaN', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        component.$el.querySelector('.js-next-button .page-link').click();

        expect(spy).toHaveBeenCalledWith(4);
      });
    });

    describe('numbered buttons', () => {
      it('should render 5 pages', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 5,
          },
          change: spy,
        });

        expect(component.$el.querySelectorAll('.page').length).toEqual(5);
      });

      it('should not render any page', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        expect(component.$el.querySelectorAll('.page').length).toEqual(0);
      });
    });

    describe('spread operator', () => {
      it('should render', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: 84,
            totalPages: 10,
          },
          change: spy,
        });

        expect(component.$el.querySelector('.separator').textContent.trim()).toEqual('...');
      });

      it('should not render', () => {
        component = mountComponent({
          pageInfo: {
            nextPage: 4,
            page: 3,
            perPage: 20,
            previousPage: 2,
            total: NaN,
            totalPages: NaN,
          },
          change: spy,
        });

        expect(component.$el.querySelector('.separator')).toBeNull();
      });
    });
  });
});
