import Vue from 'vue';
import stageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

describe('stage column component', () => {
  let component;
  const mockJob = {
    id: 4250,
    name: 'test',
    status: {
      icon: 'icon_status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4250',
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4250/retry',
        method: 'post',
      },
    },
  };

  beforeEach(() => {
    const StageColumnComponent = Vue.extend(stageColumnComponent);

    const mockJobs = [];
    for (let i = 0; i < 3; i += 1) {
      const mockedJob = Object.assign({}, mockJob);
      mockedJob.id += i;
      mockJobs.push(mockedJob);
    }

    component = new StageColumnComponent({
      propsData: {
        title: 'foo',
        jobs: mockJobs,
      },
    }).$mount();
  });

  it('should render provided title', () => {
    expect(component.$el.querySelector('.stage-name').textContent.trim()).toEqual('foo');
  });

  it('should render the provided jobs', () => {
    expect(component.$el.querySelectorAll('.builds-container > ul > li').length).toEqual(3);
  });
});
