import Vue from 'vue';
import multipleAssigneesComponent from '~/vue_sidebar_assignees/components/expanded/multiple_assignees';
import VueSpecHelper from '../../helpers/vue_spec_helper';
import { mockUser, mockUser2, mockUser3 } from '../mock_data';

describe('MultipleAssignees', () => {
  const mockStore = {
    users: [mockUser, mockUser2],
    defaultRenderCount: 1,
    rootPath: 'rootPath',
  };

  const createComponent = props =>
    VueSpecHelper.createComponent(Vue, multipleAssigneesComponent, props);

  describe('props', () => {
    it('should have store prop', () => {
      const { store } = multipleAssigneesComponent.props;
      expect(store.type).toBe(Object);
    });
  });

  describe('computed', () => {
    describe('renderShowMoreSection', () => {
      it('should return true when users.length is greater than defaultRenderCount', () => {
        const vm = createComponent({
          store: mockStore,
        });
        expect(vm.renderShowMoreSection).toEqual(true);
      });

      it('should return false when users.length is not greater than defaultRenderCount', () => {
        const newStore = Object.assign({}, mockStore);
        newStore.defaultRenderCount = 5;

        const vm = createComponent({
          store: newStore,
        });
        expect(vm.renderShowMoreSection).toEqual(false);
      });
    });

    describe('numberOfHiddenAssignees', () => {
      it('should return number of assignees that are not rendered', () => {
        const vm = createComponent({
          store: mockStore,
        });
        expect(vm.numberOfHiddenAssignees).toEqual(1);
      });
    });

    describe('isHiddenAssignees', () => {
      it('should return true when numberOfHiddenAssignees is greater than zero', () => {
        const vm = createComponent({
          store: mockStore,
        });
        expect(vm.isHiddenAssignees).toEqual(true);
      });

      it('should return false when numberOfHiddenAssignees is zero', () => {
        const newStore = Object.assign({}, mockStore);
        newStore.defaultRenderCount = 2;

        const vm = createComponent({
          store: newStore,
        });
        expect(vm.isHiddenAssignees).toEqual(false);
      });
    });
  });

  describe('methods', () => {
    describe('toggleShowLess', () => {
      it('should toggle showLess', () => {
        const vm = createComponent({
          store: mockStore,
        });

        expect(vm.showLess).toEqual(true);
        vm.toggleShowLess();
        expect(vm.showLess).toEqual(false);
      });
    });

    describe('renderAssignee', () => {
      it('should return true if showLess is false', () => {
        const vm = createComponent({
          store: mockStore,
        });
        vm.showLess = false;
        expect(vm.renderAssignee(0)).toEqual(true);
      });

      it('should return true if showLess is true and index is less than defaultRenderCount', () => {
        const vm = createComponent({
          store: mockStore,
        });
        vm.showLess = true;
        expect(vm.renderAssignee(0)).toEqual(true);
      });

      it('should return false if showLess is true and index is greater than defaultRenderCount', () => {
        const vm = createComponent({
          store: mockStore,
        });
        vm.showLess = true;
        expect(vm.renderAssignee(10)).toEqual(false);
      });
    });

    describe('assigneeUrl', () => {
      it('should return url', () => {
        const vm = createComponent({
          store: mockStore,
        });

        const username = 'username';
        expect(vm.assigneeUrl(username)).toEqual(`${mockStore.rootPath}${username}`);
      });
    });

    describe('assigneeAlt', () => {
      it('should return alt', () => {
        const vm = createComponent({
          store: mockStore,
        });

        const name = 'name';
        expect(vm.assigneeAlt(name)).toEqual(`${name}'s avatar`);
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    describe('userItem', () => {
      let userItems;

      beforeEach(() => {
        const newStore = Object.assign({}, mockStore);
        newStore.defaultRenderCount = 2;

        // Create a new copy to prevent mutating `mockStore.users`
        const users = Object.assign([], mockStore.users);
        users.push(mockUser3);
        newStore.users = users;

        vm = createComponent({
          store: newStore,
        });
        el = vm.$el;

        userItems = el.querySelectorAll('.user-item');
      });

      it('should render multiple user-item', () => {
        expect(userItems.length).toEqual(2);
      });

      it('should render href', () => {
        [].forEach.call(userItems, (item, index) => {
          const user = vm.store.users[index];
          const a = item.querySelector('a');
          expect(a.getAttribute('href')).toEqual(vm.assigneeUrl(user.username));
        });
      });

      it('should render anchor title', () => {
        [].forEach.call(userItems, (item, index) => {
          const user = vm.store.users[index];
          const a = item.querySelector('a');
          expect(a.getAttribute('data-title')).toEqual(user.name);
        });
      });

      it('should render image alt', () => {
        [].forEach.call(userItems, (item, index) => {
          const user = vm.store.users[index];
          const img = item.querySelector('img');
          expect(img.getAttribute('alt')).toEqual(vm.assigneeAlt(user.name));
        });
      });

      it('should render image', () => {
        [].forEach.call(userItems, (item, index) => {
          const user = vm.store.users[index];
          const img = item.querySelector('img');
          expect(img.getAttribute('src')).toEqual(user.avatarUrl);
        });
      });
    });

    describe('userListMore', () => {
      beforeEach(() => {
        vm = createComponent({
          store: mockStore,
        });
        el = vm.$el;
      });

      it('should render user-list-more', () => {
        const userListMore = el.querySelector('.user-list-more');
        expect(userListMore).toBeDefined();
      });

      it('should toggle user-list-more', (done) => {
        const button = el.querySelector('button');
        const buttonContent = button.textContent;

        button.click();

        Vue.nextTick(() => {
          expect(button.textContent.trim()).not.toEqual(buttonContent);
          done();
        });
      });

      it('should render show less', () => {
        const button = el.querySelector('button');
        expect(button.textContent.trim()).toEqual('+ 1 more');
      });

      describe('show more', () => {
        let button;

        beforeEach(() => {
          button = el.querySelector('button');
        });

        it('should render show more', (done) => {
          button.click();
          Vue.nextTick(() => {
            expect(button.textContent.trim()).toEqual('- show less');
            done();
          });
        });

        it('should render number of hidden assignees', (done) => {
          const count = el.querySelectorAll('.user-item').length;
          button.click();

          Vue.nextTick(() => {
            expect(el.querySelectorAll('.user-item').length > count).toEqual(true);
            done();
          });
        });
      });
    });
  });
});
