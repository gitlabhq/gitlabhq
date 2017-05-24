/* global boardsMockInterceptor */
/* global boardObj */
/* global BoardService */

import Vue from 'vue';
import milestoneSelect from '~/boards/components/milestone_select';
import '~/boards/services/board_service';
import '~/boards/stores/boards_store';
import './mock_data';

describe('Milestone select component', () => {
  let selectMilestoneSpy;
  let vm;

  beforeEach(() => {
    const MilestoneComp = Vue.extend(milestoneSelect);

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
      expect(vm.extraMilestones.length).toBe(3);
      expect(vm.extraMilestones[0].title).toBe('Any Milestone');
      expect(vm.extraMilestones[1].title).toBe('Upcoming');
      expect(vm.extraMilestones[2].title).toBe('Started');
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
        expect(vm.$el.querySelectorAll('.board-milestone-list li').length).toBe(5);
        expect(
          vm.$el.querySelectorAll('.board-milestone-list li')[4].textContent,
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

      it('selects started milestone', () => {
        vm.$el.querySelectorAll('.board-milestone-list a')[2].click();

        expect(selectMilestoneSpy).toHaveBeenCalledWith({
          id: -3,
          title: 'Started',
        });
      });

      it('selects fetched milestone', () => {
        vm.$el.querySelectorAll('.board-milestone-list a')[3].click();

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
