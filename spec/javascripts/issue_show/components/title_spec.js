import Vue from 'vue';
import Store from '~/issue_show/stores';
import titleComponent from '~/issue_show/components/title.vue';

describe('Title component', () => {
  let vm;

  beforeEach(() => {
    const Component = Vue.extend(titleComponent);
    vm = new Component({
      propsData: {
        issuableRef: '#1',
        titleHtml: 'Testing <img />',
        titleText: 'Testing',
        showForm: false,
        store: new Store({
          titleHtml: '',
          descriptionHtml: '',
          issuableRef: '',
        }),
      },
    }).$mount();
  });

  it('renders title HTML', () => {
    expect(
      vm.$el.querySelector('h2').innerHTML.trim(),
    ).toBe('Testing <img>');
  });

  it('updates page title when changing titleHtml', (done) => {
    spyOn(vm, 'setPageTitle');
    vm.titleHtml = 'test';

    Vue.nextTick(() => {
      expect(
        vm.setPageTitle,
      ).toHaveBeenCalled();

      done();
    });
  });

  it('animates title changes', (done) => {
    vm.titleHtml = 'test';

    Vue.nextTick(() => {
      expect(
        vm.$el.querySelector('h2').classList.contains('issue-realtime-pre-pulse'),
      ).toBeTruthy();

      setTimeout(() => {
        expect(
          vm.$el.querySelector('h2').classList.contains('issue-realtime-trigger-pulse'),
        ).toBeTruthy();

        done();
      });
    });
  });

  it('updates page title after changing title', (done) => {
    vm.titleHtml = 'changed';
    vm.titleText = 'changed';

    Vue.nextTick(() => {
      expect(
        document.querySelector('title').textContent.trim(),
      ).toContain('changed');

      done();
    });
  });
});
