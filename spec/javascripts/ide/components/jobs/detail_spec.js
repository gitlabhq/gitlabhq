import Vue from 'vue';
import JobDetail from '~/ide/components/jobs/detail.vue';
import { createStore } from '~/ide/stores';
import { createComponentWithStore } from '../../../helpers/vue_mount_component_helper';
import { jobs } from '../../mock_data';

describe('IDE jobs detail view', () => {
  const Component = Vue.extend(JobDetail);
  let vm;

  beforeEach(() => {
    const store = createStore();

    store.state.pipelines.detailJob = {
      ...jobs[0],
      isLoading: true,
      output: 'testing',
      rawPath: `${gl.TEST_HOST}/raw`,
    };

    vm = createComponentWithStore(Component, store);

    spyOn(vm, 'fetchJobTrace').and.returnValue(Promise.resolve());

    vm = vm.$mount();

    spyOn(vm.$refs.buildTrace, 'scrollTo');
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('calls fetchJobTrace on mount', () => {
    expect(vm.fetchJobTrace).toHaveBeenCalled();
  });

  it('scrolls to bottom on mount', done => {
    setTimeout(() => {
      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalled();

      done();
    });
  });

  it('renders job output', () => {
    expect(vm.$el.querySelector('.bash').textContent).toContain('testing');
  });

  it('renders empty message output', done => {
    vm.$store.state.pipelines.detailJob.output = '';

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.bash').textContent).toContain('No messages were logged');

      done();
    });
  });

  it('renders loading icon', () => {
    expect(vm.$el.querySelector('.build-loader-animation')).not.toBe(null);
    expect(vm.$el.querySelector('.build-loader-animation').style.display).toBe('');
  });

  it('hide loading icon when isLoading is false', done => {
    vm.$store.state.pipelines.detailJob.isLoading = false;

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.build-loader-animation').style.display).toBe('none');

      done();
    });
  });

  it('resets detailJob when clicking header button', () => {
    spyOn(vm, 'setDetailJob');

    vm.$el.querySelector('.btn').click();

    expect(vm.setDetailJob).toHaveBeenCalledWith(null);
  });

  it('renders raw path link', () => {
    expect(vm.$el.querySelector('.controllers-buttons').getAttribute('href')).toBe(
      `${gl.TEST_HOST}/raw`,
    );
  });

  describe('scroll buttons', () => {
    it('triggers scrollDown when clicking down button', done => {
      spyOn(vm, 'scrollDown');

      vm.$el.querySelectorAll('.btn-scroll')[1].click();

      vm.$nextTick(() => {
        expect(vm.scrollDown).toHaveBeenCalled();

        done();
      });
    });

    it('triggers scrollUp when clicking up button', done => {
      spyOn(vm, 'scrollUp');

      vm.scrollPos = 1;

      vm
        .$nextTick()
        .then(() => vm.$el.querySelector('.btn-scroll').click())
        .then(() => vm.$nextTick())
        .then(() => {
          expect(vm.scrollUp).toHaveBeenCalled();
        })
        .then(done)
        .catch(done.fail);
    });
  });

  describe('scrollDown', () => {
    it('scrolls build trace to bottom', () => {
      spyOnProperty(vm.$refs.buildTrace, 'scrollHeight').and.returnValue(1000);

      vm.scrollDown();

      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalledWith(0, 1000);
    });
  });

  describe('scrollUp', () => {
    it('scrolls build trace to top', () => {
      vm.scrollUp();

      expect(vm.$refs.buildTrace.scrollTo).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('scrollBuildLog', () => {
    beforeEach(() => {
      spyOnProperty(vm.$refs.buildTrace, 'offsetHeight').and.returnValue(100);
      spyOnProperty(vm.$refs.buildTrace, 'scrollHeight').and.returnValue(200);
    });

    it('sets scrollPos to bottom when at the bottom', done => {
      spyOnProperty(vm.$refs.buildTrace, 'scrollTop').and.returnValue(100);

      vm.scrollBuildLog();

      setTimeout(() => {
        expect(vm.scrollPos).toBe(1);

        done();
      });
    });

    it('sets scrollPos to top when at the top', done => {
      spyOnProperty(vm.$refs.buildTrace, 'scrollTop').and.returnValue(0);
      vm.scrollPos = 1;

      vm.scrollBuildLog();

      setTimeout(() => {
        expect(vm.scrollPos).toBe(0);

        done();
      });
    });

    it('resets scrollPos when not at top or bottom', done => {
      spyOnProperty(vm.$refs.buildTrace, 'scrollTop').and.returnValue(10);

      vm.scrollBuildLog();

      setTimeout(() => {
        expect(vm.scrollPos).toBe('');

        done();
      });
    });
  });
});
