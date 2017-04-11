import Vue from 'vue';
import tabs from '~/blob/xlsx/components/tabs.vue';
import eventHub from '~/blob/xlsx/eventhub';

describe('XLSX tabs', () => {
  let vm;

  beforeEach((done) => {
    const TabsComponent = Vue.extend(tabs);

    vm = new TabsComponent({
      propsData: {
        currentSheetName: 'test 1',
        sheetNames: ['test 1', 'test 2'],
      },
    }).$mount();

    Vue.nextTick(done);
  });

  it('changes hash to sheet name', (done) => {
    eventHub.$on('update-sheet', (name) => {
      expect(
        name,
      ).toBe('test 2');

      done();
    });

    vm.changeSheet('test 2');
  });

  it('selects current sheet name', () => {
    expect(
      vm.$el.querySelector('li:first-child'),
    ).toHaveClass('active');

    expect(
      vm.$el.querySelector('li:nth-child(2)'),
    ).not.toHaveClass('active');
  });

  it('getTabPath returns encoded path', () => {
    expect(
      vm.getTabPath('test 2'),
    ).toBe(`#${encodeURIComponent('test 2')}`);
  });
});
