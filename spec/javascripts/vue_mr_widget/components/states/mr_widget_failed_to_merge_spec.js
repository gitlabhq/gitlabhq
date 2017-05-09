import Vue from 'vue';
import failedToMergeComponent from '~/vue_merge_request_widget/components/states/mr_widget_failed_to_merge';
import eventHub from '~/vue_merge_request_widget/event_hub';

const mr = {
  mergeError: 'Merge error happened.',
};
const createComponent = () => {
  const Component = Vue.extend(failedToMergeComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetFailedToMerge', () => {
  describe('data', () => {
    it('should have default data', () => {
      const data = failedToMergeComponent.data();

      expect(data.timer).toEqual(10);
      expect(data.isRefreshing).toBeFalsy();
    });
  });

  describe('computed', () => {
    describe('timerText', () => {
      it('should return correct timer text', () => {
        const vm = createComponent();
        expect(vm.timerText).toEqual('10 seconds');

        vm.timer = 1;
        expect(vm.timerText).toEqual('a second');
      });
    });
  });

  describe('created', () => {
    it('should disable polling', () => {
      spyOn(eventHub, '$emit');
      createComponent();

      expect(eventHub.$emit).toHaveBeenCalledWith('DisablePolling');
    });
  });

  describe('methods', () => {
    describe('refresh', () => {
      it('should emit event to request component refresh', () => {
        spyOn(eventHub, '$emit');
        const vm = createComponent();

        expect(vm.isRefreshing).toBeFalsy();

        vm.refresh();
        expect(vm.isRefreshing).toBeTruthy();
        expect(eventHub.$emit).toHaveBeenCalledWith('MRWidgetUpdateRequested');
        expect(eventHub.$emit).toHaveBeenCalledWith('EnablePolling');
      });
    });

    describe('updateTimer', () => {
      it('should update timer and emit event when timer end', () => {
        const vm = createComponent();
        spyOn(vm, 'refresh');

        expect(vm.timer).toEqual(10);

        for (let i = 0; i < 10; i++) { // eslint-disable-line
          expect(vm.timer).toEqual(10 - i);
          vm.updateTimer();
        }

        expect(vm.refresh).toHaveBeenCalled();
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;

    beforeEach(() => {
      vm = createComponent();
      el = vm.$el;
    });

    it('should have correct elements', (done) => {
      expect(el.classList.contains('mr-widget-body')).toBeTruthy();
      expect(el.innerText).toContain('Merge error happened.');
      expect(el.innerText).toContain('Refreshing in 10 seconds');
      expect(el.innerText).not.toContain('Merge failed.');
      expect(el.querySelector('button').getAttribute('disabled')).toBeTruthy();
      expect(el.querySelector('button').innerText).toContain('Merge');
      expect(el.querySelector('.js-refresh-button').innerText).toContain('Refresh now');
      expect(el.querySelector('.js-refresh-label')).toEqual(null);
      expect(el.innerText).not.toContain('Refreshing now...');
      setTimeout(() => {
        expect(el.innerText).toContain('Refreshing in 9 seconds');
        done();
      }, 1010);
    });

    it('should just generic merge failed message if merge_error is not available', (done) => {
      vm.mr.mergeError = null;

      Vue.nextTick(() => {
        expect(el.innerText).toContain('Merge failed.');
        expect(el.innerText).not.toContain('Merge error happened.');
        done();
      });
    });

    it('should show refresh label when refresh requested', () => {
      vm.refresh();
      Vue.nextTick(() => {
        expect(el.innerText).not.toContain('Merge failed. Refreshing');
        expect(el.innerText).toContain('Refreshing now...');
      });
    });
  });
});
