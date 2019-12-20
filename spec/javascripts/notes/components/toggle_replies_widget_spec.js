import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import toggleRepliesWidget from '~/notes/components/toggle_replies_widget.vue';
import { note } from '../mock_data';

const deepCloneObject = obj => JSON.parse(JSON.stringify(obj));

describe('toggle replies widget for notes', () => {
  let vm;
  let ToggleRepliesWidget;
  const noteFromOtherUser = deepCloneObject(note);
  noteFromOtherUser.author.username = 'fatihacet';

  const noteFromAnotherUser = deepCloneObject(note);
  noteFromAnotherUser.author.username = 'mgreiling';
  noteFromAnotherUser.author.name = 'Mike Greiling';

  const replies = [note, note, note, noteFromOtherUser, noteFromAnotherUser];

  beforeEach(() => {
    ToggleRepliesWidget = Vue.extend(toggleRepliesWidget);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('collapsed state', () => {
    beforeEach(() => {
      vm = mountComponent(ToggleRepliesWidget, {
        replies,
        collapsed: true,
      });
    });

    it('should render the collapsed', () => {
      const vmTextContent = vm.$el.textContent.replace(/\s\s+/g, ' ');

      expect(vm.$el.classList.contains('collapsed')).toEqual(true);
      expect(vm.$el.querySelectorAll('.user-avatar-link').length).toEqual(3);
      expect(vm.$el.querySelector('time')).not.toBeNull();
      expect(vmTextContent).toContain('5 replies');
      expect(vmTextContent).toContain(`Last reply by ${noteFromAnotherUser.author.name}`);
    });

    it('should emit toggle event when the replies text clicked', () => {
      const spy = spyOn(vm, '$emit');

      vm.$el.querySelector('.js-replies-text').click();

      expect(spy).toHaveBeenCalledWith('toggle');
    });
  });

  describe('expanded state', () => {
    beforeEach(() => {
      vm = mountComponent(ToggleRepliesWidget, {
        replies,
        collapsed: false,
      });
    });

    it('should render expanded state', () => {
      const vmTextContent = vm.$el.textContent.replace(/\s\s+/g, ' ');

      expect(vm.$el.querySelector('.collapse-replies-btn')).not.toBeNull();
      expect(vmTextContent).toContain('Collapse replies');
    });

    it('should emit toggle event when the collapse replies text called', () => {
      const spy = spyOn(vm, '$emit');

      vm.$el.querySelector('.js-collapse-replies').click();

      expect(spy).toHaveBeenCalledWith('toggle');
    });
  });
});
