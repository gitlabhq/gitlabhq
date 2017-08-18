import Vue from 'vue';
import stageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

describe('stage column component', () => {
  let component;
  const mockJob = {
    id: 4256,
    name: 'test',
    status: {
      icon: 'icon_status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4256',
      action: {
        icon: 'icon_action_retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
  };

  beforeEach(() => {
    const StageColumnComponent = Vue.extend(stageColumnComponent);

    component = new StageColumnComponent({
      propsData: {
        title: 'foo',
        jobs: [mockJob, mockJob, mockJob],
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
