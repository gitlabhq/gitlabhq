//= require vue
//= require vue_pagination/index

describe('Pagination component', () => {
  let component;

  const changeChanges = {
    one: '',
    two: '',
  };

  const change = (one, two) => {
    changeChanges.one = one;
    changeChanges.two = two;
  };

  it('should render and start at page 1', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    });

    expect(component.$el.classList).toContain('gl-pagination');

    component.changepage({ target: { innerText: '1' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the previous page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 3,
          previousPage: 1,
        },
        change,
      },
    });

    component.changepage({ target: { innerText: 'Prev' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the next page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changepage({ target: { innerText: 'Next' } });

    expect(changeChanges.one).toEqual(5);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the last page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changepage({ target: { innerText: 'Last >>' } });

    expect(changeChanges.one).toEqual(10);
    expect(changeChanges.two).toEqual('all');
  });

  it('should go to the first page', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 5,
          previousPage: 3,
        },
        change,
      },
    });

    component.changepage({ target: { innerText: '<< First' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });

  it('should do nothing', () => {
    fixture.set('<div class="test-pagination-container"></div>');

    component = new window.gl.VueGlPagination({
      el: document.querySelector('.test-pagination-container'),
      propsData: {
        pageInfo: {
          totalPages: 10,
          nextPage: 2,
          previousPage: '',
        },
        change,
      },
    });

    component.changepage({ target: { innerText: '...' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });
});
