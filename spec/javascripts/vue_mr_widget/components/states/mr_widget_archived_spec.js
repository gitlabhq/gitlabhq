import Vue from 'vue';
import archivedComponent from '~/vue_merge_request_widget/components/states/mr_widget_archived';

describe('MRWidgetArchived', () => {
  describe('template', () => {
    it('should have correct elements', () => {
      const Component = Vue.extend(archivedComponent);
      const el = new Component({
        el: document.createElement('div'),
      }).$el;

      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.querySelector('button').classList.contains('btn-success')).toBeTruthy();
      expect(el.querySelector('button').disabled).toBeTruthy();
      expect(el.innerText).toContain('This project is archived, write access has been disabled.');
    });
  });
});
