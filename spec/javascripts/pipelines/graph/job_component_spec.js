import Vue from 'vue';
import jobComponent from '~/pipelines/components/graph/job_component.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('pipeline graph job component', () => {
  let JobComponent;
  let component;

  const mockJob = {
    id: 4256,
    name: 'test',
    status: {
      icon: 'icon_status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4256',
      has_details: true,
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
  };

  beforeEach(() => {
    JobComponent = Vue.extend(jobComponent);
  });

  afterEach(() => {
    component.$destroy();
  });

  describe('name with link', () => {
    it('should render the job name and status with a link', (done) => {
      component = mountComponent(JobComponent, { job: mockJob });

      Vue.nextTick(() => {
        const link = component.$el.querySelector('a');

        expect(link.getAttribute('href')).toEqual(mockJob.status.details_path);

        expect(
          link.getAttribute('data-original-title'),
        ).toEqual(`${mockJob.name} - ${mockJob.status.label}`);

        expect(component.$el.querySelector('.js-status-icon-success')).toBeDefined();

        expect(
          component.$el.querySelector('.ci-status-text').textContent.trim(),
        ).toEqual(mockJob.name);

        done();
      });
    });
  });

  describe('name without link', () => {
    it('it should render status and name', () => {
      component = mountComponent(JobComponent, {
        job: {
          id: 4257,
          name: 'test',
          status: {
            icon: 'icon_status_success',
            text: 'passed',
            label: 'passed',
            group: 'success',
            details_path: '/root/ci-mock/builds/4257',
            has_details: false,
          },
        },
      });

      expect(component.$el.querySelector('.js-status-icon-success')).toBeDefined();
      expect(component.$el.querySelector('a')).toBeNull();

      expect(
        component.$el.querySelector('.ci-status-text').textContent.trim(),
      ).toEqual(mockJob.name);
    });
  });

  describe('action icon', () => {
    it('it should render the action icon', () => {
      component = mountComponent(JobComponent, { job: mockJob });

      expect(component.$el.querySelector('a.ci-action-icon-container')).toBeDefined();
      expect(component.$el.querySelector('i.ci-action-icon-wrapper')).toBeDefined();
    });
  });

  describe('dropdown', () => {
    it('should render the dropdown action icon', () => {
      component = mountComponent(JobComponent, {
        job: mockJob,
        isDropdown: true,
      });

      expect(component.$el.querySelector('a.ci-action-icon-wrapper')).toBeDefined();
    });
  });

  it('should render provided class name', () => {
    component = mountComponent(JobComponent, {
      job: mockJob,
      cssClassJobName: 'css-class-job-name',
    });

    expect(
      component.$el.querySelector('a').classList.contains('css-class-job-name'),
    ).toBe(true);
  });

  describe('status label', () => {
    it('should not render status label when it is not provided', () => {
      component = mountComponent(JobComponent, {
        job: {
          id: 4258,
          name: 'test',
          status: {
            icon: 'icon_status_success',
          },
        },
      });

      expect(component.$el.querySelector('.js-job-component-tooltip').getAttribute('data-original-title')).toEqual('test');
    });

    it('should not render status label when it is  provided', () => {
      component = mountComponent(JobComponent, {
        job: {
          id: 4259,
          name: 'test',
          status: {
            icon: 'icon_status_success',
            label: 'success',
            tooltip: 'success',
          },
        },
      });

      expect(component.$el.querySelector('.js-job-component-tooltip').getAttribute('data-original-title')).toEqual('test - success');
    });
  });
});
