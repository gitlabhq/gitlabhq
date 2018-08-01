import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import TimeagoAuto from '~/vue_shared/components/time_ago_auto.vue';

function sendTick(ticker) {
  ticker.dispatchEvent(new Event('tick'));
}

describe('vue_shared TimeagoAuto component', () => {
  const TEST_TIME = new Date('2018-07-25T08:00:00Z');
  let ticker;
  let vm;

  beforeEach(() => {
    ticker = new EventTarget();
    vm = mountComponent(Vue.extend(TimeagoAuto), {
      time: TEST_TIME,
      ticker,
    });
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('calls update on every tick', () => {
    const updateSpy = spyOn(vm, 'update');

    sendTick(ticker);
    sendTick(ticker);
    sendTick(ticker);

    expect(updateSpy).toHaveBeenCalledTimes(3);
  });

  it('updates timeText on update', done => {
    const fakeTimeText = 'Lorem Ipsum Dolar Sit Amit';
    const timeFormattedSpy = spyOn(vm, 'timeFormated').and.returnValue(fakeTimeText);

    vm.update();

    Vue.nextTick(() => {
      expect(timeFormattedSpy).toHaveBeenCalledTimes(1);
      expect(vm.$el).toHaveText(fakeTimeText);
      done();
    });
  });
});
