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

  it('should change page to 2 and previous should go cak to 1', () => {
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

    component.changepage({ target: { innerText: '2' } });

    expect(changeChanges.one).toEqual(2);
    expect(changeChanges.two).toEqual('all');

    component.changepage({ target: { innerText: 'Prev' } });

    expect(changeChanges.one).toEqual(1);
    expect(changeChanges.two).toEqual('all');
  });
});
