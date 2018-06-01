import Vue from 'vue';
import Stage from '~/ide/components/jobs/stage.vue';
import { stages, jobs } from '../../mock_data';

describe('IDE pipeline stage', () => {
  const Component = Vue.extend(Stage);
  let vm;
  let stage;

  beforeEach(() => {
    stage = {
      ...stages[0],
      id: 0,
      dropdownPath: stages[0].dropdown_path,
      jobs: [...jobs],
      isLoading: false,
      isCollapsed: false,
    };

    vm = new Component({
      propsData: { stage },
    });

    spyOn(vm, '$emit');

    vm.$mount();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('emits fetch event when mounted', () => {
    expect(vm.$emit).toHaveBeenCalledWith('fetch', vm.stage);
  });

  it('renders stages details', () => {
    expect(vm.$el.textContent).toContain(vm.stage.name);
  });

  it('renders CI icon', () => {
    expect(vm.$el.querySelector('.ic-status_failed')).not.toBe(null);
  });

  describe('collapsed', () => {
    it('emits event when clicking header', done => {
      vm.$el.querySelector('.card-header').click();

      vm.$nextTick(() => {
        expect(vm.$emit).toHaveBeenCalledWith('toggleCollapsed', vm.stage.id);

        done();
      });
    });

    it('toggles collapse status when collapsed', done => {
      vm.stage.isCollapsed = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.card-body').style.display).toBe('none');

        done();
      });
    });

    it('sets border bottom class when collapsed', done => {
      vm.stage.isCollapsed = true;

      vm.$nextTick(() => {
        expect(vm.$el.querySelector('.card-header').classList).toContain('border-bottom-0');

        done();
      });
    });
  });

  it('renders jobs count', () => {
    expect(vm.$el.querySelector('.badge').textContent).toContain('4');
  });

  it('renders loading icon when no jobs and isLoading is true', done => {
    vm.stage.isLoading = true;
    vm.stage.jobs = [];

    vm.$nextTick(() => {
      expect(vm.$el.querySelector('.loading-container')).not.toBe(null);

      done();
    });
  });

  it('renders list of jobs', () => {
    expect(vm.$el.querySelectorAll('.ide-job-item').length).toBe(4);
  });
});
