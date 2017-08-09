import Vue from 'vue';
import issueNoteHeader from '~/notes/components/issue_note_header.vue';
import store from '~/notes/stores';

describe('issue_note_header component', () => {
  let vm;
  let Component;

  beforeEach(() => {
    Component = Vue.extend(issueNoteHeader);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('individual note', () => {
    beforeEach(() => {
      vm = new Component({
        store,
        propsData: {
          actionText: 'commented',
          actionTextHtml: '',
          author: {
            avatar_url: null,
            id: 1,
            name: 'Root',
            path: '/root',
            state: 'active',
            username: 'root',
          },
          createdAt: '2017-08-02T10:51:58.559Z',
          includeToggle: false,
          noteId: 1394,
        },
      }).$mount();
    });

    it('should render user information', () => {
      expect(
        vm.$el.querySelector('.note-header-author-name').textContent.trim(),
      ).toEqual('Root');
      expect(
        vm.$el.querySelector('.note-header-info a').getAttribute('href'),
      ).toEqual('/root');
    });

    it('should render timestamp link', () => {
      expect(vm.$el.querySelector('a[href="#note_1394"]')).toBeDefined();
    });
  });

  describe('discussion', () => {
    beforeEach(() => {
      vm = new Component({
        store,
        propsData: {
          actionText: 'started a discussion',
          actionTextHtml: '',
          author: {
            avatar_url: null,
            id: 1,
            name: 'Root',
            path: '/root',
            state: 'active',
            username: 'root',
          },
          createdAt: '2017-08-02T10:51:58.559Z',
          includeToggle: true,
          noteId: 1395,
        },
      }).$mount();
    });

    it('should render toggle button', () => {
      expect(vm.$el.querySelector('.js-vue-toggle-button')).toBeDefined();
    });

    it('should toggle the disucssion icon', (done) => {
      expect(
        vm.$el.querySelector('.js-vue-toggle-button i').classList.contains('fa-chevron-up'),
      ).toEqual(true);

      vm.$el.querySelector('.js-vue-toggle-button').click();

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.js-vue-toggle-button i').classList.contains('fa-chevron-down'),
        ).toEqual(true);
        done();
      });
    });
  });
});
