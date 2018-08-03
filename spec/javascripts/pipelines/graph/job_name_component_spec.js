import Vue from 'vue';
import jobNameComponent from '~/pipelines/components/graph/job_name_component.vue';

describe('job name component', () => {
  let component;

  beforeEach(() => {
    const JobNameComponent = Vue.extend(jobNameComponent);
    component = new JobNameComponent({
      propsData: {
        name: 'foo',
        status: {
          icon: 'status_success',
        },
      },
    }).$mount();
  });

  it('should render the provided name', () => {
    expect(component.$el.querySelector('.ci-status-text').textContent.trim()).toEqual('foo');
  });

  it('should render an icon with the provided status', () => {
    expect(component.$el.querySelector('.ci-status-icon-success')).toBeDefined();
    expect(component.$el.querySelector('.ci-status-icon-success svg')).toBeDefined();
  });
});
