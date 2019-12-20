import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import axios from '~/lib/utils/axios_utils';
import stage from '~/pipelines/components/stage.vue';
import eventHub from '~/pipelines/event_hub';
import { stageReply } from './mock_data';

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
          icon: 'status_success',
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

  describe('with successful request', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, stageReply);
    });

    it('should render the received data and emit `clickedDropdown` event', done => {
      spyOn(eventHub, '$emit');
      component.$el.querySelector('button').click();

      setTimeout(() => {
        expect(
          component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
        ).toContain(stageReply.latest_statuses[0].name);

        expect(eventHub.$emit).toHaveBeenCalledWith('clickedDropdown');
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
      const copyStage = Object.assign({}, stageReply);
      copyStage.latest_statuses[0].name = 'this is the updated content';
      mock.onGet('bar.json').reply(200, copyStage);
    });

    it('should update the stage to request the new endpoint provided', done => {
      component.stage = {
        status: {
          group: 'running',
          icon: 'status_running',
          title: 'running',
        },
        dropdown_path: 'bar.json',
      };

      Vue.nextTick(() => {
        component.$el.querySelector('button').click();

        setTimeout(() => {
          expect(
            component.$el.querySelector('.js-builds-dropdown-container ul').textContent.trim(),
          ).toContain('this is the updated content');
          done();
        });
      });
    });
  });

  describe('pipelineActionRequestComplete', () => {
    beforeEach(() => {
      mock.onGet('path.json').reply(200, stageReply);

      mock.onPost(`${stageReply.latest_statuses[0].status.action.path}.json`).reply(200);
    });

    describe('within pipeline table', () => {
      it('emits `refreshPipelinesTable` event when `pipelineActionRequestComplete` is triggered', done => {
        spyOn(eventHub, '$emit');

        component.type = 'PIPELINES_TABLE';
        component.$el.querySelector('button').click();

        setTimeout(() => {
          component.$el.querySelector('.js-ci-action').click();
          setTimeout(() => {
            component
              .$nextTick()
              .then(() => {
                expect(eventHub.$emit).toHaveBeenCalledWith('refreshPipelinesTable');
              })
              .then(done)
              .catch(done.fail);
          }, 0);
        }, 0);
      });
    });
  });
});
