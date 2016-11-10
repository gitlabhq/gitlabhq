/*= require vue_common_components/commit */
/* eslint-disable */

describe('Commit component', () => {
  const getRenderedText = (Component, propsData) => {
    const Constructor = Vue.extend(Component);
    const vm = new Constructor({propsData}).$mount();    
    return vm.$el.textContent;
  };
  
  const MyComponent = window.gl.commitComponent;

  describe('When `ref` is provided', () => {
    const props = {
      tag: true,
      ref: {
        name: 'master',
        ref_url: 'http://localhost/namespace2/gitlabhq/tree/master'
      },
      commit_url: 'https://gitlab.com/gitlab-org/gitlab-ce/commit/b7836eddf62d663c665769e1b0960197fd215067',
      short_sha: 'b7836edd',
      title: 'Commit message',
      author: {
        avatar_url: 'https://gitlab.com/uploads/user/avatar/300478/avatar.png',
        web_url: 'https://gitlab.com/jschatz1',
        username: 'jschatz1'
      }
    };

    it('should render a tag icon if it represents a tag', () => {
      const renderedText = getRenderedText(MyComponent, props);

    });

    it('should render a code-fork icon if it does not represent a tag', () => {

    });

    it('should render a link to the ref url', () => {

    });

    it('should render the ref name', () => {

    });
  });
});

it('should render the commit icon as an svg', () => {

});

it('should render the commit short sha with a link to the commit url', () => {

});

describe('Given commit title and author props', () => {
  it('Should render a link to the author profile', () => {

  });

  it('Should render the author avatar with title and alt attributes', () => {

  });
});

describe('When commit title is not provided', () => {
  it('Should render default message', () => {

  });
});

describe('Given no ref prop', () => {
  it('Should render without errors', () => {

  });
});

describe('Given no title prop', () => {
  it('Should render without errors', () => {

  });
});

describe('Given no author prop', () => {
  it('Should render without errors', () => {

  });
});