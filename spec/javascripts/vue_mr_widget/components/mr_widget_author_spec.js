import Vue from 'vue';
import authorComponent from '~/vue_merge_request_widget/components/mr_widget_author';

const createComponent = () => {
  const Component = Vue.extend(authorComponent);
  const author = {
    webUrl: 'http://foo.bar',
    avatarUrl: 'http://gravatar.com/foo',
    name: 'fatihacet',
  };

  return new Component({
    el: document.createElement('div'),
    propsData: { author },
  });
};

describe('MRWidgetAuthor', () => {
  describe('props', () => {
    it('should have props', () => {
      const { author } = authorComponent.props;

      expect(author).toBeDefined();
      expect(author.type instanceof Object).toBeTruthy();
      expect(author.required).toBeTruthy();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = createComponent().$el;

      expect(el.tagName).toEqual('A');
      expect(el.getAttribute('href')).toEqual('http://foo.bar');
      expect(el.querySelector('img').getAttribute('src')).toEqual('http://gravatar.com/foo');
      expect(el.querySelector('.author').innerText).toEqual('fatihacet');
    });
  });
});
