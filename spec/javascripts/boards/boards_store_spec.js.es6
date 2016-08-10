//= require jquery
//= require jquery_ujs
//= require jquery.cookie
//= require vue
//= require vue-resource
//= require lib/utils/url_utility
//= require boards/models/issue
//= require boards/models/label
//= require boards/models/list
//= require boards/models/user
//= require boards/services/board_service
//= require boards/stores/boards_store
//= require ./mock_data

(() => {
  beforeEach(() => {
    gl.boardService = new BoardService('/test/issue-boards/board');
    BoardsStore.create();

    $.cookie('issue_board_welcome_hidden', 'false');
  });

  describe('Store', () => {
    it('starts with a blank state', () => {
      expect(BoardsStore.state.lists.length).toBe(0);
    });

    describe('lists', () => {
      it('creates new list without persisting to DB', () => {
        BoardsStore.addList(listObj);

        expect(BoardsStore.state.lists.length).toBe(1);
      });

      it('finds list by ID', () => {
        BoardsStore.addList(listObj);
        const list = BoardsStore.findList('id', 1);

        expect(list.id).toBe(1);
      });

      it('finds list by type', () => {
        BoardsStore.addList(listObj);
        const list = BoardsStore.findList('type', 'label');

        expect(list).toBeDefined();
      });

      it('gets issue when new list added', (done) => {
        BoardsStore.addList(listObj);
        const list = BoardsStore.findList('id', 1);

        expect(BoardsStore.state.lists.length).toBe(1);

        setTimeout(() => {
          expect(list.issues.length).toBe(1);
          done();
        }, 0);
      });

      it('persists new list', (done) => {
        BoardsStore.new({
          title: 'Test',
          type: 'label',
          label: {
            id: 1,
            title: 'Testing',
            color: 'red',
            description: 'testing;'
          }
        });
        expect(BoardsStore.state.lists.length).toBe(1);

        setTimeout(() => {
          const list = BoardsStore.findList('id', 1);
          expect(list).toBeDefined();
          expect(list.id).toBe(1);
          expect(list.position).toBe(0);
          done();
        }, 0);
      });

      it('check for blank state adding', () => {
        expect(BoardsStore.shouldAddBlankState()).toBe(true);
      });

      it('check for blank state not adding', () => {
        BoardsStore.addList(listObj);
        expect(BoardsStore.shouldAddBlankState()).toBe(false);
      });

      it('check for blank state adding when backlog & done list exist', () => {
        BoardsStore.addList({
          list_type: 'backlog'
        });
        BoardsStore.addList({
          list_type: 'done'
        });

        expect(BoardsStore.shouldAddBlankState()).toBe(true);
      });

      it('adds the blank state', () => {
        BoardsStore.addBlankState();

        const list = BoardsStore.findList('type', 'blank');
        expect(list).toBeDefined();
      });

      it('removes list from state', () => {
        BoardsStore.addList(listObj);

        expect(BoardsStore.state.lists.length).toBe(1);

        BoardsStore.removeList(1);

        expect(BoardsStore.state.lists.length).toBe(0);
      });

      it('moves the position of lists', () => {
        BoardsStore.addList(listObj);
        BoardsStore.addList(listObjDuplicate);

        expect(BoardsStore.state.lists.length).toBe(2);

        BoardsStore.moveList(0, 1);

        const list = BoardsStore.findList('id', 1);
        expect(list.position).toBe(1);
      });

      it('moves an issue from one list to another', (done) => {
        BoardsStore.addList(listObj);
        BoardsStore.addList(listObjDuplicate);

        expect(BoardsStore.state.lists.length).toBe(2);

        setTimeout(() => {
          const list = BoardsStore.findList('id', 1);
          const listTwo = BoardsStore.findList('id', 2);

          expect(list.issues.length).toBe(1);
          expect(listTwo.issues.length).toBe(1);

          BoardsStore.moveCardToList(1, 2, 1);

          expect(list.issues.length).toBe(0);
          expect(listTwo.issues.length).toBe(1);

          done();
        });
      });
    });
  });
})();
