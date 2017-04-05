import Vue from 'vue';
import avatarComponent from '~/vue_sidebar_assignees/components/collapsed/avatar';
import VueSpecHelper from '../../helpers/vue_spec_helper';
import { mockUser } from '../mock_data';

describe('CollapsedAvatar', () => {
  const createComponent = props =>
    VueSpecHelper.createComponent(Vue, avatarComponent, props);

  describe('computed', () => {
    describe('alt', () => {
      it('returns avatar alt text', () => {
        const vm = createComponent(mockUser);

        expect(vm.alt).toEqual(`${mockUser.name}'s avatar`);
      });
    });
  });

  describe('template', () => {
    it('should render alt text', () => {
      const vm = createComponent(mockUser);
      const el = vm.$el;

      const avatar = el.querySelector('.avatar');
      expect(avatar.getAttribute('alt')).toEqual(vm.alt);
    });

    it('should render avatar src url', () => {
      const el = createComponent(mockUser).$el;

      const avatar = el.querySelector('.avatar');
      expect(avatar.getAttribute('src')).toEqual(mockUser.avatarUrl);
    });

    it('should render name', () => {
      const el = createComponent(mockUser).$el;

      const span = el.querySelector('.author');
      expect(span.textContent).toEqual(mockUser.name);
    });
  });
});
