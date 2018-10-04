import Vue from 'vue';
import eventHub from '~/deploy_keys/eventhub';
import actionBtn from '~/deploy_keys/components/action_btn.vue';

describe('Deploy keys action btn', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  const deployKey = data.enabled_keys[0];
  let vm;

  beforeEach(done => {
    const ActionBtnComponent = Vue.extend({
      components: {
        actionBtn,
      },
      data() {
        return {
          deployKey,
        };
      },
      template: `
        <action-btn
          :deploy-key="deployKey"
          type="enable">
            Enable
        </action-btn>`,
    });

    vm = new ActionBtnComponent().$mount();

    Vue.nextTick()
      .then(done)
      .catch(done.fail);
  });

  it('renders the default slot', () => {
    expect(vm.$el.textContent.trim()).toBe('Enable');
  });

  it('sends eventHub event with btn type', done => {
    spyOn(eventHub, '$emit');

    vm.$el.click();

    Vue.nextTick(() => {
      expect(eventHub.$emit).toHaveBeenCalledWith('enable.key', deployKey, jasmine.anything());

      done();
    });
  });

  it('shows loading spinner after click', done => {
    vm.$el.click();

    Vue.nextTick(() => {
      expect(vm.$el.querySelector('.fa')).toBeDefined();

      done();
    });
  });

  it('disables button after click', done => {
    vm.$el.click();

    Vue.nextTick(() => {
      expect(vm.$el.classList.contains('disabled')).toBeTruthy();

      expect(vm.$el.getAttribute('disabled')).toBe('disabled');

      done();
    });
  });
});
