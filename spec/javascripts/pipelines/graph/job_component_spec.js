import Vue from 'vue';
import jobComponent from '~/pipelines/components/graph/job_component.vue';

describe('pipeline graph job component', () => {
  let JobComponent;

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
    JobComponent = Vue.extend(jobComponent);
  });

  describe('name with link', () => {
    it('should render the job name and status with a link', () => {
      const component = new JobComponent({
        propsData: {
          job: mockJob,
        },
      }).$mount();

      const link = component.$el.querySelector('a');

      expect(link.getAttribute('href')).toEqual(mockJob.status.details_path);

      expect(
        link.getAttribute('data-original-title'),
      ).toEqual(`${mockJob.name} - ${mockJob.status.label}`);

      expect(component.$el.querySelector('.js-status-icon-success')).toBeDefined();

      expect(
        component.$el.querySelector('.ci-status-text').textContent.trim(),
      ).toEqual(mockJob.name);
    });
  });

  describe('name without link', () => {
    it('it should render status and name', () => {
      const component = new JobComponent({
        propsData: {
          job: {
            id: 4256,
            name: 'test',
            status: {
              icon: 'icon_status_success',
              text: 'passed',
              label: 'passed',
              group: 'success',
              details_path: '/root/ci-mock/builds/4256',
            },
          },
        },
      }).$mount();

      expect(component.$el.querySelector('.js-status-icon-success')).toBeDefined();

      expect(
        component.$el.querySelector('.ci-status-text').textContent.trim(),
      ).toEqual(mockJob.name);
    });
  });

  describe('action icon', () => {
    it('it should render the action icon', () => {
      const component = new JobComponent({
        propsData: {
          job: mockJob,
        },
      }).$mount();

      expect(component.$el.querySelector('a.ci-action-icon-container')).toBeDefined();
      expect(component.$el.querySelector('i.ci-action-icon-wrapper')).toBeDefined();
    });
  });

  describe('dropdown', () => {
    it('should render the dropdown action icon', () => {
      const component = new JobComponent({
        propsData: {
          job: mockJob,
          isDropdown: true,
        },
      }).$mount();

      expect(component.$el.querySelector('a.ci-action-icon-wrapper')).toBeDefined();
    });
  });

  it('should render provided class name', () => {
    const component = new JobComponent({
      propsData: {
        job: mockJob,
        cssClassJobName: 'css-class-job-name',
      },
    }).$mount();

    expect(
      component.$el.querySelector('a').classList.contains('css-class-job-name'),
    ).toBe(true);
  });
});
