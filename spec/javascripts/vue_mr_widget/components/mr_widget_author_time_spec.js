import Vue from 'vue';
import authorTimeComponent from '~/vue_merge_request_widget/components/mr_widget_author_time';

const createComponent = () => {
  const Component = Vue.extend(authorTimeComponent);
  const props = {
    actionText: 'Merged by',
    author: {
      webUrl: 'http://foo.bar',
      avatarUrl: 'http://gravatar.com/foo',
      name: 'fatihacet',
    },
    dateTitle: '2017-03-23T23:02:00.807Z',
    dateReadable: '12 hours ago',
  };

  return new Component({
    el: document.createElement('div'),
    propsData: props,
  });
};

describe('MRWidgetAuthorTime', () => {
  describe('props', () => {
    it('should have props', () => {
      const { actionText, author, dateTitle, dateReadable } = authorTimeComponent.props;
      const ActionTextClass = actionText.type();
      const DateTitleClass = dateTitle.type();
      const DateReadableClass = dateReadable.type();

      expect(new ActionTextClass() instanceof String).toBeTruthy();
      expect(actionText.required).toBeTruthy();

      expect(author.type instanceof Object).toBeTruthy();
      expect(author.required).toBeTruthy();

      expect(new DateTitleClass() instanceof String).toBeTruthy();
      expect(dateTitle.required).toBeTruthy();

      expect(new DateReadableClass() instanceof String).toBeTruthy();
      expect(dateReadable.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components', () => {
      expect(authorTimeComponent.components['mr-widget-author']).toBeDefined();
    });
  });

  describe('template', () => {
    it('should have correct elements', () => {
      const el = createComponent().$el;

      expect(el.tagName).toEqual('H4');
      expect(el.querySelector('a').getAttribute('href')).toEqual('http://foo.bar');
      expect(el.querySelector('time').innerText).toContain('12 hours ago');
      expect(el.querySelector('time').getAttribute('title')).toEqual('2017-03-23T23:02:00.807Z');
    });
  });
});
