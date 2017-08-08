import Vue from 'vue';
import issueNotesApp from '~/notes/components/issue_notes_app.vue';
import service from '~/notes/services/issue_notes_service';
import * as mockData from '../mock_data';

describe('issue_note_app', () => {
  let mountComponent;
  let vm;

  const individualNoteInterceptor = (request, next) => {
    next(request.respondWith(JSON.stringify(mockData.individualNoteServerResponse), {
      status: 200,
    }));
  };

  const discussionNoteInterceptor = (request, next) => {
    next(request.respondWith(JSON.stringify(mockData.discussionNoteServerResponse), {
      status: 200,
    }));
  };

  beforeEach(() => {
    const IssueNotesApp = Vue.extend(issueNotesApp);

    mountComponent = (data) => {
      const props = data || {
        issueData: mockData.issueDataMock,
        notesData: mockData.notesDataMock,
        userData: mockData.userDataMock,
      };

      return new IssueNotesApp({
        propsData: props,
      }).$mount();
    };
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('set data', () => {
    const responseInterceptor = (request, next) => {
      next(request.respondWith(JSON.stringify([]), {
        status: 200,
      }));
    };

    beforeEach(() => {
      Vue.http.interceptors.push(responseInterceptor);
      vm = mountComponent();
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
    beforeEach(() => {
      Vue.http.interceptors.push(individualNoteInterceptor);
      vm = mountComponent();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, individualNoteInterceptor);
    });

    it('should render list of notes', (done) => {
      const note = mockData.individualNoteServerResponse[0].notes[0];

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

    it('should render form comment button as disabled', () => {
      expect(
        vm.$el.querySelector('.js-note-new-discussion').getAttribute('disabled'),
      ).toEqual('disabled');
    });
  });

  describe('while fetching data', () => {
    beforeEach(() => {
      vm = mountComponent();
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
      beforeEach(() => {
        Vue.http.interceptors.push(individualNoteInterceptor);
        spyOn(service, 'updateNote').and.callFake(() => Promise.resolve());
        vm = mountComponent();
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, individualNoteInterceptor);
      });

      it('renders edit form', (done) => {
        setTimeout(() => {
          vm.$el.querySelector('.js-note-edit').click();
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.js-vue-issue-note-form')).toBeDefined();
            done();
          });
        }, 0);
      });

      it('calls the service to update the note', (done) => {
        setTimeout(() => {
          vm.$el.querySelector('.js-note-edit').click();
          Vue.nextTick(() => {
            vm.$el.querySelector('.js-vue-issue-note-form').value = 'this is a note';
            vm.$el.querySelector('.js-vue-issue-save').click();

            expect(service.updateNote).toHaveBeenCalled();
            done();
          });
        }, 0);
      });
    });

    describe('dicussion note', () => {
      beforeEach(() => {
        Vue.http.interceptors.push(discussionNoteInterceptor);
        spyOn(service, 'updateNote').and.callFake(() => Promise.resolve());
        vm = mountComponent();
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, discussionNoteInterceptor);
      });

      it('renders edit form', (done) => {
        setTimeout(() => {
          vm.$el.querySelector('.js-note-edit').click();
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.js-vue-issue-note-form')).toBeDefined();
            done();
          });
        }, 0);
      });

      it('updates the note and resets the edit form', (done) => {
        setTimeout(() => {
          vm.$el.querySelector('.js-note-edit').click();
          Vue.nextTick(() => {
            vm.$el.querySelector('.js-vue-issue-note-form').value = 'this is a note';
            vm.$el.querySelector('.js-vue-issue-save').click();

            expect(service.updateNote).toHaveBeenCalled();
            done();
          });
        }, 0);
      });
    });
  });

  describe('new note form', () => {
    beforeEach(() => {
      vm = mountComponent();
    });

    it('should render markdown docs url', () => {
      const { markdownDocs } = mockData.notesDataMock;
      expect(vm.$el.querySelector(`a[href="${markdownDocs}"]`).textContent.trim()).toEqual('Markdown');
    });

    it('should render quick action docs url', () => {
      const { quickActionsDocs } = mockData.notesDataMock;
      expect(vm.$el.querySelector(`a[href="${quickActionsDocs}"]`).textContent.trim()).toEqual('quick actions');
    });
  });

  describe('edit form', () => {
    beforeEach(() => {
      Vue.http.interceptors.push(individualNoteInterceptor);
      vm = mountComponent();
    });

    afterEach(() => {
      Vue.http.interceptors = _.without(Vue.http.interceptors, individualNoteInterceptor);
    });

    it('should render markdown docs url', (done) => {
      setTimeout(() => {
        vm.$el.querySelector('.js-note-edit').click();
        const { markdownDocs } = mockData.notesDataMock;

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector(`.edit-note a[href="${markdownDocs}"]`).textContent.trim(),
          ).toEqual('Markdown is supported');
          done();
        });
      }, 0);
    });

    it('should not render quick actions docs url', (done) => {
      setTimeout(() => {
        vm.$el.querySelector('.js-note-edit').click();
        const { quickActionsDocs } = mockData.notesDataMock;

        Vue.nextTick(() => {
          expect(
            vm.$el.querySelector(`.edit-note a[href="${quickActionsDocs}"]`),
          ).toEqual(null);
          done();
        });
      }, 0);
    });
  });

  // TODO: FILIPA
  describe('create new note', () => {
    it('should show placeholder note while new comment is being posted', () => {});
    it('should remove placeholder note when new comment is done posting', () => {});
    it('should show actual note element when new comment is done posting', () => {});
    it('should show flash error message when new comment failed to be posted', () => {});
    it('should show flash error message when comment failed to be updated', () => {});
  });
});
