import Vue from 'vue';
import paginationComp from '~/vue_shared/components/table_pagination';
import '~/lib/utils/common_utils';

describe('Pagination component', () => {
  let component;
  let PaginationComponent;

  const changeChanges = {
    one: '',
  };

  const change = (one) => {
    changeChanges.one = one;
  };

  beforeEach(() => {
    PaginationComponent = Vue.extend(paginationComp);
  });

  it('should render and start at page 1', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    }).$mount();

    expect(component.$el.classList).toContain('gl-pagination');

    component.changePage({ target: { innerText: '1' } });

    expect(changeChanges.one).toEqual(1);
  });

  it('should go to the previous page', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 3,
          previousPage: 1,
        },
        change,
      },
    }).$mount();

    component.changePage({ target: { innerText: 'Prev' } });

    expect(changeChanges.one).toEqual(1);
  });

  it('should go to the next page', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    }).$mount();

    component.changePage({ target: { innerText: 'Next' } });

    expect(changeChanges.one).toEqual(5);
  });

  it('should go to the last page', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    }).$mount();

    component.changePage({ target: { innerText: 'Last »' } });

    expect(changeChanges.one).toEqual(10);
  });

  it('should go to the first page', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    }).$mount();

    component.changePage({ target: { innerText: '« First' } });

    expect(changeChanges.one).toEqual(1);
  });

  it('should do nothing', () => {
    component = new PaginationComponent({
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    }).$mount();

    component.changePage({ target: { innerText: '...' } });

    expect(changeChanges.one).toEqual(1);
  });
});

describe('paramHelper', () => {
  afterEach(() => {
    window.history.pushState({}, null, '');
  });

  it('can parse url parameters correctly', () => {
    window.history.pushState({}, null, '?scope=all&p=2');

    const scope = gl.utils.getParameterByName('scope');
    const p = gl.utils.getParameterByName('p');

    expect(scope).toEqual('all');
    expect(p).toEqual('2');
  });

  it('returns null if param not in url', () => {
    window.history.pushState({}, null, '?p=2');

    const scope = gl.utils.getParameterByName('scope');
    const p = gl.utils.getParameterByName('p');

    expect(scope).toEqual(null);
    expect(p).toEqual('2');
  });
});
