import Vue from 'vue';
import issueNotesApp from '~/notes/components/issue_notes_app.vue';
import service from '~/notes/services/issue_notes_service';
import { keyboardDownEvent } from '../../issue_show/helpers';
import * as mockData from '../mock_data';

describe('issue_note_app', () => {
  let mountComponent;

  beforeEach(() => {
    const IssueNotesApp = Vue.extend(issueNotesApp);

    mountComponent = props => new IssueNotesApp({
      propsData: props,
    }).$mount();
  });

  describe('set data', () => {
    let vm;

    const responseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(responseInterceptor);
      vm = mountComponent({
        issueData: mockData.issueDataMock,
        notesData: mockData.notesDataMock,
        userData: mockData.userDataMock,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, responseInterceptor);
    });

    it('should set notes data', () => {
      expect(vm.$store.state.notesData).toEqual(mockData.notesDataMock);
    });

    it('should set issue data', () => {
      expect(vm.$store.state.issueData).toEqual(mockData.issueDataMock);
    });

    it('should set user data', () => {
      expect(vm.$store.state.userData).toEqual(mockData.userDataMock);
    });

    it('should fetch notes', () => {
      expect(vm.$store.state.notes).toEqual([]);
    });
  });

  describe('render', () => {
    let vm;

    const responseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify(mockData.discussionResponse), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(responseInterceptor);
      vm = mountComponent({
        issueData: mockData.issueDataMock,
        notesData: mockData.notesDataMock,
        userData: mockData.userDataMock,
      });
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, responseInterceptor);
    });

    it('should render list of notes', (done) => {
      const note = mockData.discussionResponse[0].notes[0];

      setTimeout(() => {
        expect(
          vm.$el.querySelector('.main-notes-list .note-header-author-name').textContent.trim(),
        ).toEqual(note.author.name);

        expect(vm.$el.querySelector('.main-notes-list .note-text').innerHTML).toEqual(note.note_html);
        done();
      }, 0);
    });

    it('should render form', () => {
      expect(vm.$el.querySelector('.js-main-target-form').tagName).toEqual('FORM');
      expect(
        vm.$el.querySelector('.js-main-target-form textarea').getAttribute('placeholder'),
      ).toEqual('Write a comment or drag your files here...');
    });
  });

  describe('while fetching data', () => {
    let vm;
    beforeEach(() => {
      vm = mountComponent({
        issueData: mockData.issueDataMock,
        notesData: mockData.notesDataMock,
        userData: mockData.userDataMock,
      });
    });

    it('should render loading icon', () => {
      expect(vm.$el.querySelector('.js-loading')).toBeDefined();
    });

    it('should render form', () => {
      expect(vm.$el.querySelector('.js-main-target-form').tagName).toEqual('FORM');
      expect(
        vm.$el.querySelector('.js-main-target-form textarea').getAttribute('placeholder'),
      ).toEqual('Write a comment or drag your files here...');
    });
  });

  describe('update note', () => {
    describe('individual note', () => {
      let vm;

      const responseInterceptor = (request, next) => {
        next(request.respondWith(JSON.stringify(mockData.discussionResponse), {
          status: 200,
        }));
      };

      beforeEach(() => {
        Vue.http.interceptors.push(responseInterceptor);

        vm = mountComponent({
          issueData: mockData.issueDataMock,
          notesData: mockData.notesDataMock,
          userData: mockData.userDataMock,
        });

      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, responseInterceptor);
      });

      it('renders edit form', () => {
        setTimeout(() => {
          vm.$el.querySelector('.js-note-edit').click();
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.js-vue-issue-note-form')).toBeDefined();
          });
        }, 0);
      });

      it('updates the note and resets the edit form', () => {});
    });

    describe('dicussion note note', () => {
      it('renders edit form', () => {
      });

      it('updates the note and resets the edit form', () => {});
    });
  });

  describe('set target hash', () => {
    it('updates the URL when the note date is clicked', () => {

    });

    it('stores the correct hash', () => {

    });

    it('updates visually the target note', () => {

    });
  });

  describe('create new note', () => {
    it('should show placeholder note while new comment is being posted', () => {});
    it('should remove placeholder note when new comment is done posting', () => {});
    it('should show actual note element when new comment is done posting', () => {});
    it('should show flash error message when new comment failed to be posted', () => {});
    it('should show flash error message when comment failed to be updated', () => {});
  });

  describe('quick actions', () => {
    it('should return executing quick action description when note has single quick action', () => {
    });

    it('should return generic multiple quick action description when note has multiple quick actions', () => {
    });

    it('should return generic quick action description when available quick actions list is not populated', () => {
    });
  });

  describe('new note form', () => {
    it('should render markdown docs url', () => {

    });

    it('should render quick action docs url', () => {

    });

    it('should preview markdown', () => {

    });

    describe('discard draft', () => {
      it('should reset form when reset button is clicked', () => {

      });
    });
  });

  describe('edit form', () => {
    it('should render markdown docs url', () => {});
    it('should not render quick actions docs url', () => {});
  });
});
