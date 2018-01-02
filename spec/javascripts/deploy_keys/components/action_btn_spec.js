import Vue from 'vue';
import eventHub from '~/deploy_keys/eventhub';
import actionBtn from '~/deploy_keys/components/action_btn.vue';

describe('Deploy keys action btn', () => {
  const data = getJSONFixture('deploy_keys/keys.json');
  const deployKey = data.enabled_keys[0];
  let vm;

  beforeEach((done) => {
    const ActionBtnComponent = Vue.extend(actionBtn);

    vm = new ActionBtnComponent({
      propsData: {
        deployKey,
        type: 'enable',
      },
    }).$mount();

    setTimeout(done);
  });

  it('renders the type as uppercase', () => {
    expect(
      vm.$el.textContent.trim(),
    ).toBe('Enable');
  });

  it('sends eventHub event with btn type', (done) => {
    spyOn(eventHub, '$emit');

    vm.$el.click();

    setTimeout(() => {
      expect(
        eventHub.$emit,
      ).toHaveBeenCalledWith('enable.key', deployKey, jasmine.anything());

      done();
    });
  });

  it('shows loading spinner after click', (done) => {
    vm.$el.click();

    setTimeout(() => {
      expect(
        vm.$el.querySelector('.fa'),
      ).toBeDefined();

      done();
    });
  });

  it('disables button after click', (done) => {
    vm.$el.click();

    setTimeout(() => {
      expect(
        vm.$el.classList.contains('disabled'),
      ).toBeTruthy();

      expect(
        vm.$el.getAttribute('disabled'),
      ).toBe('disabled');

      done();
    });
  });
});
