import Vue from 'vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import stageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

describe('stage column component', () => {
  let component;
  const StageColumnComponent = Vue.extend(stageColumnComponent);

  const mockJob = {
    id: 4250,
    name: 'test',
    status: {
      icon: 'status_success',
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
    const mockGroups = [];
    for (let i = 0; i < 3; i += 1) {
      const mockedJob = Object.assign({}, mockJob);
      mockedJob.id += i;
      mockGroups.push(mockedJob);
    }

    component = mountComponent(StageColumnComponent, {
      title: 'foo',
      groups: mockGroups,
      hasTriggeredBy: false,
    });
  });

  it('should render provided title', () => {
    expect(component.$el.querySelector('.stage-name').textContent.trim()).toEqual('foo');
  });

  it('should render the provided groups', () => {
    expect(component.$el.querySelectorAll('.builds-container > ul > li').length).toEqual(3);
  });

  describe('jobId', () => {
    it('escapes job name', () => {
      component = mountComponent(StageColumnComponent, {
        groups: [
          {
            id: 4259,
            name: '<img src=x onerror=alert(document.domain)>',
            status: {
              icon: 'status_success',
              label: 'success',
              tooltip: '<img src=x onerror=alert(document.domain)>',
            },
          },
        ],
        title: 'test',
        hasTriggeredBy: false,
      });

      expect(component.$el.querySelector('.builds-container li').getAttribute('id')).toEqual(
        'ci-badge-&lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });
  });

  describe('with action', () => {
    it('renders action button', () => {
      component = mountComponent(StageColumnComponent, {
        groups: [
          {
            id: 4259,
            name: '<img src=x onerror=alert(document.domain)>',
            status: {
              icon: 'status_success',
              label: 'success',
              tooltip: '<img src=x onerror=alert(document.domain)>',
            },
          },
        ],
        title: 'test',
        hasTriggeredBy: false,
        action: {
          icon: 'play',
          title: 'Play all',
          path: 'action',
        },
      });

      expect(component.$el.querySelector('.js-stage-action')).not.toBeNull();
    });
  });

  describe('without action', () => {
    it('does not render action button', () => {
      component = mountComponent(StageColumnComponent, {
        groups: [
          {
            id: 4259,
            name: '<img src=x onerror=alert(document.domain)>',
            status: {
              icon: 'status_success',
              label: 'success',
              tooltip: '<img src=x onerror=alert(document.domain)>',
            },
          },
        ],
        title: 'test',
        hasTriggeredBy: false,
      });

      expect(component.$el.querySelector('.js-stage-action')).toBeNull();
    });
  });
});
