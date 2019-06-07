import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import Vue from 'vue';
import registry from '~/registry/components/app.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';
import { reposServerResponse } from '../mock_data';

describe('Registry List', () => {
  const Component = Vue.extend(registry);
  let vm;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
    vm.$destroy();
  });

  describe('with data', () => {
    beforeEach(() => {
      mock.onGet(`${TEST_HOST}/foo`).replyOnce(200, reposServerResponse);

      vm = mountComponent(Component, { endpoint: `${TEST_HOST}/foo` });
    });

    it('should render a list of repos', done => {
      setTimeout(() => {
        expect(vm.$store.state.repos.length).toEqual(reposServerResponse.length);

        Vue.nextTick(() => {
          expect(vm.$el.querySelectorAll('.container-image').length).toEqual(
            reposServerResponse.length,
          );
          done();
        });
      }, 0);
    });

    describe('delete repository', () => {
      it('should be possible to delete a repo', done => {
        setTimeout(() => {
          Vue.nextTick(() => {
            expect(vm.$el.querySelector('.container-image-head .js-remove-repo')).toBeDefined();
            done();
          });
        }, 0);
      });
    });

    describe('toggle repository', () => {
      it('should open the container', done => {
        setTimeout(() => {
          Vue.nextTick(() => {
            vm.$el.querySelector('.js-toggle-repo').click();
            Vue.nextTick(() => {
              expect(
                vm.$el.querySelector('.js-toggle-repo use').getAttribute('xlink:href'),
              ).toContain('angle-up');
              done();
            });
          });
        }, 0);
      });
    });
  });

  describe('without data', () => {
    beforeEach(() => {
      mock.onGet(`${TEST_HOST}/foo`).replyOnce(200, []);

      vm = mountComponent(Component, { endpoint: `${TEST_HOST}/foo` });
    });

    it('should render empty message', done => {
      setTimeout(() => {
        expect(
          vm.$el
            .querySelector('p')
            .textContent.trim()
            .replace(/[\r\n]+/g, ' '),
        ).toEqual(
          'No container images stored for this project. Add one by following the instructions above.',
        );
        done();
      }, 0);
    });
  });

  describe('while loading data', () => {
    beforeEach(() => {
      mock.onGet(`${TEST_HOST}/foo`).replyOnce(200, []);

      vm = mountComponent(Component, { endpoint: `${TEST_HOST}/foo` });
    });

    it('should render a loading spinner', done => {
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.spinner')).not.toBe(null);
        done();
      });
    });
  });
});
