import Vue from 'vue';
import tabs from '~/blob/xlsx/components/tabs.vue';

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

  it('changes hash to sheet name', () => {
    vm.changeSheet('test 2');

    expect(
      location.hash,
    ).toBe(`#${encodeURIComponent('test 2')}`);
  });

  it('selects current sheet name', () => {
    expect(
      vm.$el.querySelector('li:first-child'),
    ).toHaveClass('active');

    expect(
      vm.$el.querySelector('li:nth-child(2)'),
    ).not.toHaveClass('active');
  });
});
