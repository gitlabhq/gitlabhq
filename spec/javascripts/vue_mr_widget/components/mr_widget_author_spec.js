import Vue from 'vue';
import authorComponent from '~/vue_merge_request_widget/components/mr_widget_author';

const author = {
  webUrl: 'http://foo.bar',
  avatarUrl: 'http://gravatar.com/foo',
  name: 'fatihacet',
};
const createComponent = () => {
  const Component = Vue.extend(authorComponent);

  return new Component({
    el: document.createElement('div'),
    propsData: { author },
  });
};

describe('MRWidgetAuthor', () => {
  describe('props', () => {
    it('should have props', () => {
      const authorProp = authorComponent.props.author;

      expect(authorProp).toBeDefined();
      expect(authorProp.type instanceof Object).toBeTruthy();
      expect(authorProp.required).toBeTruthy();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = createComponent().$el;

      expect(el.tagName).toEqual('A');
      expect(el.getAttribute('href')).toEqual(author.webUrl);
      expect(el.querySelector('img').getAttribute('src')).toEqual(author.avatarUrl);
      expect(el.querySelector('.author').innerText.trim()).toEqual(author.name);
    });
  });
});
