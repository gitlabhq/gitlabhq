import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import stage from '~/pipelines/components/stage.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Pipelines stage component', () => {
  let StageComponent;
  let component;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    StageComponent = Vue.extend(stage);

    component = mountComponent(StageComponent, {
      stage: {
        status: {
          group: 'success',
          icon: 'icon_status_success',
          title: 'success',
        },
        dropdown_path: 'path.json',
      },
      updateDropdown: false,
    });
  });

  afterEach(() => {
    component.$destroy();
    mock.restore();
  });

  it('should render a dropdown with the status icon', () => {
    expect(component.$el.getAttribute('class')).toEqual('dropdown');
    expect(component.$el.querySelector('svg')).toBeDefined();
    expect(component.$el.querySelector('button').getAttribute('data-toggle')).toEqual('dropdown');
  });

  describe('with successfull request', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, { html: 'foo' });
    });

    it('should render the received data', done => {
      component.$el.querySelector('button').click();

      setTimeout(() => {
        expect(
          component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
        ).toEqual('foo');
        done();
      }, 0);
    });
  });

  describe('when request fails', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(500);
    });

    it('should close the dropdown', () => {
      component.$el.click();

      setTimeout(() => {
        expect(component.$el.classList.contains('open')).toEqual(false);
      }, 0);
    });
  });

  describe('update endpoint correctly', () => {
    beforeEach(() => {
      mock.onGet('bar.json').reply(200, { html: 'this is the updated content' });
    });

    it('should update the stage to request the new endpoint provided', done => {
      component.stage = {
        status: {
          group: 'running',
          icon: 'running',
          title: 'running',
        },
        dropdown_path: 'bar.json',
      };

      Vue.nextTick(() => {
        component.$el.querySelector('button').click();

        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
          ).toEqual('this is the updated content');
          done();
        });
      });
    });
  });
});
