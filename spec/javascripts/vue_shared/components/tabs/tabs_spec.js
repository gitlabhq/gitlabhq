import Vue from 'vue';
import Tabs from '~/vue_shared/components/tabs/tabs';
import Tab from '~/vue_shared/components/tabs/tab.vue';

describe('Tabs component', () => {
  let vm;

  beforeEach(done => {
    vm = new Vue({
      components: {
        Tabs,
        Tab,
      },
      template: `
        <div>
          <tabs>
            <tab title="Testing" active>
              First tab
            </tab>
            <tab>
              <template slot="title">Test slot</template>
              Second tab
            </tab>
          </tabs>
        </div>
      `,
    }).$mount();

    setTimeout(done);
  });

  describe('tab links', () => {
    it('renders links for tabs', () => {
      expect(vm.$el.querySelectorAll('a').length).toBe(2);
    });

    it('renders link titles from props', () => {
      expect(vm.$el.querySelector('a').textContent).toContain('Testing');
    });

    it('renders link titles from slot', () => {
      expect(vm.$el.querySelectorAll('a')[1].textContent).toContain('Test slot');
    });

    it('renders active class', () => {
      expect(vm.$el.querySelector('a').classList).toContain('active');
    });

    it('updates active class on click', done => {
      vm.$el.querySelectorAll('a')[1].click();

      setTimeout(() => {
        expect(vm.$el.querySelector('a').classList).not.toContain('active');
        expect(vm.$el.querySelectorAll('a')[1].classList).toContain('active');

        done();
      });
    });
  });

  describe('content', () => {
    it('renders content panes', () => {
      expect(vm.$el.querySelectorAll('.tab-pane').length).toBe(2);
      expect(vm.$el.querySelectorAll('.tab-pane')[0].textContent).toContain('First tab');
      expect(vm.$el.querySelectorAll('.tab-pane')[1].textContent).toContain('Second tab');
    });
  });
});
