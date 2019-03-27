import $ from 'jquery';
import _ from 'underscore';
import Vue from 'vue';
import { mount, createLocalVue } from '@vue/test-utils';
import NotesApp from '~/notes/components/notes_app.vue';
import service from '~/notes/services/notes_service';
import createStore from '~/notes/stores';
import '~/behaviors/markdown/render_gfm';
import * as mockData from '../mock_data';

describe('note_app', () => {
  let mountComponent;
  let wrapper;
  let store;

  beforeEach(() => {
    $('body').attr('data-page', 'projects:merge_requests:show');

    store = createStore();
    mountComponent = data => {
      const propsData = data || {
        noteableData: mockData.noteableDataMock,
        notesData: mockData.notesDataMock,
        userData: mockData.userDataMock,
      };
      const localVue = createLocalVue();

      return mount(
        {
          components: {
            NotesApp,
          },
          template: '<div class="js-vue-notes-event"><notes-app v-bind="$attrs" /></div>',
        },
        {
          propsData,
          store,
          localVue,
          sync: false,
        },
      );
    };
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('set data', () => {
    const responseInterceptor = (request, next) => {
      next(
        request.respondWith(JSON.stringify([]), {
          status: 200,
        }),
      );
    };

    beforeEach(() => {
      Vue.http.interceptors.push(responseInterceptor);
      wrapper = mountComponent();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, responseInterceptor);
    });

    it('should set notes data', () => {
      expect(store.state.notesData).toEqual(mockData.notesDataMock);
    });

    it('should set issue data', () => {
      expect(store.state.noteableData).toEqual(mockData.noteableDataMock);
    });

    it('should set user data', () => {
      expect(store.state.userData).toEqual(mockData.userDataMock);
    });

    it('should fetch discussions', () => {
      expect(store.state.discussions).toEqual([]);
    });
  });

  describe('render', () => {
    beforeEach(() => {
      setFixtures('<div class="js-discussions-count"></div>');

      Vue.http.interceptors.push(mockData.individualNoteInterceptor);
      wrapper = mountComponent();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, mockData.individualNoteInterceptor);
    });

    it('should render list of notes', done => {
      const note =
        mockData.INDIVIDUAL_NOTE_RESPONSE_MAP.GET[
          '/gitlab-org/gitlab-ce/issues/26/discussions.json'
        ][0].notes[0];

      setTimeout(() => {
        expect(
          wrapper
            .find('.main-notes-list .note-header-author-name')
            .text()
            .trim(),
        ).toEqual(note.author.name);

        expect(wrapper.find('.main-notes-list .note-text').html()).toContain(note.note_html);
        done();
      }, 0);
    });

    it('should render form', () => {
      expect(wrapper.find('.js-main-target-form').name()).toEqual('form');
      expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });

    it('should not render form when commenting is disabled', () => {
      store.state.commentsDisabled = true;
      wrapper = mountComponent();

      expect(wrapper.find('.js-main-target-form').exists()).toBe(false);
    });

    it('should render discussion filter note `commentsDisabled` is true', () => {
      store.state.commentsDisabled = true;
      wrapper = mountComponent();

      expect(wrapper.find('.js-discussion-filter-note').exists()).toBe(true);
    });

    it('should render form comment button as disabled', () => {
      expect(wrapper.find('.js-note-new-discussion').attributes('disabled')).toEqual('disabled');
    });

    it('updates discussions badge', done => {
      setTimeout(() => {
        expect(document.querySelector('.js-discussions-count').textContent).toEqual('2');

        done();
      });
    });
  });

  describe('while fetching data', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('renders skeleton notes', () => {
      expect(wrapper.find('.animation-container').exists()).toBe(true);
    });

    it('should render form', () => {
      expect(wrapper.find('.js-main-target-form').name()).toEqual('form');
      expect(wrapper.find('.js-main-target-form textarea').attributes('placeholder')).toEqual(
        'Write a comment or drag your files here…',
      );
    });
  });

  describe('update note', () => {
    describe('individual note', () => {
      beforeEach(done => {
        Vue.http.interceptors.push(mockData.individualNoteInterceptor);
        spyOn(service, 'updateNote').and.callThrough();
        wrapper = mountComponent();
        setTimeout(() => {
          wrapper.find('.js-note-edit').trigger('click');
          Vue.nextTick(done);
        }, 0);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors,
          mockData.individualNoteInterceptor,
        );
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('calls the service to update the note', done => {
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');

        expect(service.updateNote).toHaveBeenCalled();
        // Wait for the requests to finish before destroying
        setTimeout(() => {
          done();
        });
      });
    });

    describe('discussion note', () => {
      beforeEach(done => {
        Vue.http.interceptors.push(mockData.discussionNoteInterceptor);
        spyOn(service, 'updateNote').and.callThrough();
        wrapper = mountComponent();

        setTimeout(() => {
          wrapper.find('.js-note-edit').trigger('click');
          Vue.nextTick(done);
        }, 0);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(
          Vue.http.interceptors,
          mockData.discussionNoteInterceptor,
        );
      });

      it('renders edit form', () => {
        expect(wrapper.find('.js-vue-issue-note-form').exists()).toBe(true);
      });

      it('updates the note and resets the edit form', done => {
        wrapper.find('.js-vue-issue-note-form').value = 'this is a note';
        wrapper.find('.js-vue-issue-save').trigger('click');

        expect(service.updateNote).toHaveBeenCalled();
        // Wait for the requests to finish before destroying
        setTimeout(() => {
          done();
        });
      });
    });
  });

  describe('new note form', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('should render markdown docs url', () => {
      const { markdownDocsPath } = mockData.notesDataMock;

      expect(
        wrapper
          .find(`a[href="${markdownDocsPath}"]`)
          .text()
          .trim(),
      ).toEqual('Markdown');
    });

    it('should render quick action docs url', () => {
      const { quickActionsDocsPath } = mockData.notesDataMock;

      expect(
        wrapper
          .find(`a[href="${quickActionsDocsPath}"]`)
          .text()
          .trim(),
      ).toEqual('quick actions');
    });
  });

  describe('edit form', () => {
    beforeEach(() => {
      Vue.http.interceptors.push(mockData.individualNoteInterceptor);
      wrapper = mountComponent();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, mockData.individualNoteInterceptor);
    });

    it('should render markdown docs url', done => {
      setTimeout(() => {
        wrapper.find('.js-note-edit').trigger('click');
        const { markdownDocsPath } = mockData.notesDataMock;

        Vue.nextTick(() => {
          expect(
            wrapper
              .find(`.edit-note a[href="${markdownDocsPath}"]`)
              .text()
              .trim(),
          ).toEqual('Markdown is supported');
          done();
        });
      }, 0);
    });

    it('should not render quick actions docs url', done => {
      setTimeout(() => {
        wrapper.find('.js-note-edit').trigger('click');
        const { quickActionsDocsPath } = mockData.notesDataMock;

        Vue.nextTick(() => {
          expect(wrapper.find(`.edit-note a[href="${quickActionsDocsPath}"]`).exists()).toBe(false);
          done();
        });
      }, 0);
    });
  });

  describe('emoji awards', () => {
    it('dispatches toggleAward after toggleAward event', () => {
      const toggleAwardEvent = new CustomEvent('toggleAward', {
        detail: {
          awardName: 'test',
          noteId: 1,
        },
      });
      const toggleAwardAction = jasmine.createSpy('toggleAward');
      wrapper.vm.$store.hotUpdate({
        actions: {
          toggleAward: toggleAwardAction,
        },
      });

      wrapper.vm.$parent.$el.dispatchEvent(toggleAwardEvent);

      expect(toggleAwardAction).toHaveBeenCalledTimes(1);
      const [, payload] = toggleAwardAction.calls.argsFor(0);

      expect(payload).toEqual({
        awardName: 'test',
        noteId: 1,
      });
    });
  });
});
