/* global Vue */
/* global boardsMockInterceptor */
/* global boardObj */
/* global BoardService */
const MilestoneComp = require('~/boards/components/milestone_select');
require('~/boards/services/board_service');
require('~/boards/stores/boards_store');
require('./mock_data');

describe('Milestone select component', () => {
  let selectMilestoneSpy;
  let vm;

  beforeEach(() => {
    Vue.http.interceptors.push(boardsMockInterceptor);
    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();

    selectMilestoneSpy = jasmine.createSpy('selectMilestone').and.callFake((milestone) => {
      vm.board.milestone_id = milestone.id;
    });

    vm = new MilestoneComp({
      propsData: {
        board: boardObj,
        milestonePath: '/test/issue-boards/milestones.json',
        selectMilestone: selectMilestoneSpy,
      },
    });
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
  });

  describe('before mount', () => {
    it('sets default data', () => {
      expect(vm.loading).toBe(false);
      expect(vm.milestones.length).toBe(0);
      expect(vm.extraMilestones.length).toBe(2);
      expect(vm.extraMilestones[0].title).toBe('Any Milestone');
      expect(vm.extraMilestones[1].title).toBe('Upcoming');
    });
  });

  describe('mounted', () => {
    describe('without board milestone', () => {
      beforeEach((done) => {
        vm.$mount();

        setTimeout(() => {
          done();
        });
      });

      it('loads data', () => {
        expect(vm.milestones.length).toBe(1);
      });

      it('renders the milestone list', () => {
        expect(vm.$el.querySelector('.fa-spinner')).toBeNull();
        expect(vm.$el.querySelectorAll('.board-milestone-list li').length).toBe(4);
        expect(
          vm.$el.querySelectorAll('.board-milestone-list li')[3].textContent,
        ).toContain('test');
      });

      it('selects any milestone', () => {
        vm.$el.querySelectorAll('.board-milestone-list a')[0].click();

        expect(selectMilestoneSpy).toHaveBeenCalledWith({
          id: null,
          title: 'Any Milestone',
        });
      });

      it('selects upcoming milestone', () => {
        vm.$el.querySelectorAll('.board-milestone-list a')[1].click();

        expect(selectMilestoneSpy).toHaveBeenCalledWith({
          id: -2,
          title: 'Upcoming',
        });
      });

      it('selects fetched milestone', () => {
        vm.$el.querySelectorAll('.board-milestone-list a')[2].click();

        expect(selectMilestoneSpy).toHaveBeenCalledWith({
          id: 1,
          title: 'test',
        });
      });

      it('changes selected milestone', (done) => {
        const firstLink = vm.$el.querySelectorAll('.board-milestone-list a')[0];

        firstLink.click();

        Vue.nextTick(() => {
          expect(firstLink.querySelector('.fa-check')).toBeDefined();

          done();
        });
      });
    });

    describe('with board milestone', () => {
      beforeEach((done) => {
        vm.board.milestone_id = 1;
        vm.$mount();

        setTimeout(() => {
          done();
        });
      });

      it('renders the selected milestone', () => {
        expect(vm.$el.querySelector('.board-milestone-list .fa-check')).not.toBeNull();
        expect(vm.$el.querySelectorAll('.board-milestone-list .fa-check').length).toBe(1);
      });
    });
  });
});
