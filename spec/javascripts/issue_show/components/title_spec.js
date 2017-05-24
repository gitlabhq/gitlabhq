import Vue from 'vue';
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
      },
    }).$mount();
  });

  it('renders title HTML', () => {
    expect(
      vm.$el.innerHTML.trim(),
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
        vm.$el.classList.contains('issue-realtime-pre-pulse'),
      ).toBeTruthy();

      setTimeout(() => {
        expect(
          vm.$el.classList.contains('issue-realtime-trigger-pulse'),
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
