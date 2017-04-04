import Vue from 'vue';
import VueSpecHelper from './vue_spec_helper';
import ClassSpecHelper from './class_spec_helper';

describe('VueSpecHelper', () => {
  describe('createComponent', () => {
    const sample = {
      name: 'Sample',
      props: {
        content: {
          type: String,
          required: false,
        },
      },
      template: `
        <div>{{content}}</div>
      `,
    };

    it('should be a static method', () => {
      expect(ClassSpecHelper.itShouldBeAStaticMethod(VueSpecHelper, 'createComponent').status()).toBe('passed');
    });

    it('should call Vue.extend', () => {
      spyOn(Vue, 'extend').and.callThrough();
      VueSpecHelper.createComponent(Vue, sample, {});
      expect(Vue.extend).toHaveBeenCalled();
    });

    it('should return view model', () => {
      const vm = VueSpecHelper.createComponent(Vue, sample, {
        content: 'content',
      });
      expect(vm.$el.textContent).toEqual('content');
    });
  });
});
