/* global BoardService */
/* global boardsMockInterceptor */
/* global List */
/* global listObj */
import Vue from 'vue';
import BoardDelete from '~/boards/components/board_delete';
import '~/boards/models/list';
import './mock_data';

describe('Board delete', () => {
  let list;
  let vm;

  beforeEach((done) => {
    const BoardDeleteComponent = Vue.extend(BoardDelete);

    gl.boardService = new BoardService('/test/issue-boards/board', '', '1');
    gl.issueBoards.BoardsStore.create();

    Vue.http.interceptors.push(boardsMockInterceptor);

    list = new List(listObj);

    spyOn(list, 'destroy');

    vm = new BoardDeleteComponent({
      propsData: {
        list,
      },
    }).$mount();

    Vue.nextTick(done);
  });

  afterEach(() => {
    Vue.http.interceptors = _.without(Vue.http.interceptors, boardsMockInterceptor);
  });

  it('does not destroy list if confirm is false', (done) => {
    spyOn(window, 'confirm').and.callFake(() => false);

    vm.$el.click();

    Vue.nextTick(() => {
      expect(
        list.destroy,
      ).not.toHaveBeenCalled();

      done();
    });
  });

  it('destroys list if confirm is true', (done) => {
    spyOn(window, 'confirm').and.callFake(() => true);

    vm.$el.click();

    Vue.nextTick(() => {
      expect(
        list.destroy,
      ).toHaveBeenCalled();

      done();
    });
  });
});
