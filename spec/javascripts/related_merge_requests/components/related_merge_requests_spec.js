import { mount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import RelatedIssuableItem from '~/vue_shared/components/issue/related_issuable_item.vue';
import RelatedMergeRequests from '~/related_merge_requests/components/related_merge_requests.vue';
import createStore from '~/related_merge_requests/store/index';

const FIXTURE_PATH = 'issues/related_merge_requests.json';
const API_ENDPOINT = '/api/v4/projects/2/issues/33/related_merge_requests';
const localVue = createLocalVue();

describe('RelatedMergeRequests', () => {
  let wrapper;
  let mock;
  let mockData;

  beforeEach(done => {
    loadFixtures(FIXTURE_PATH);
    mockData = getJSONFixture(FIXTURE_PATH);
    mock = new MockAdapter(axios);
    mock.onGet(`${API_ENDPOINT}?per_page=100`).reply(200, mockData, { 'x-total': 2 });

    wrapper = mount(localVue.extend(RelatedMergeRequests), {
      localVue,
      store: createStore(),
      propsData: {
        endpoint: API_ENDPOINT,
        projectNamespace: 'gitlab-org',
        projectPath: 'gitlab-ce',
      },
    });

    setTimeout(done);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('methods', () => {
    describe('getAssignees', () => {
      const assignees = [{ name: 'foo' }, { name: 'bar' }];

      describe('when there is assignees array', () => {
        it('should return assignees array', () => {
          const mr = { assignees };

          expect(wrapper.vm.getAssignees(mr)).toEqual(assignees);
        });
      });

      it('should return an array with single assingee', () => {
        const mr = { assignee: assignees[0] };

        expect(wrapper.vm.getAssignees(mr)).toEqual([assignees[0]]);
      });

      it('should return empty array when assignee is not set', () => {
        expect(wrapper.vm.getAssignees({})).toEqual([]);
        expect(wrapper.vm.getAssignees({ assignee: null })).toEqual([]);
      });
    });
  });

  describe('template', () => {
    it('should render related merge request items', () => {
      expect(wrapper.find('.js-items-count').text()).toEqual('2');
      expect(wrapper.findAll(RelatedIssuableItem).length).toEqual(2);

      const props = wrapper
        .findAll(RelatedIssuableItem)
        .at(1)
        .props();
      const data = mockData[1];

      expect(props.idKey).toEqual(data.id);
      expect(props.pathIdSeparator).toEqual('!');
      expect(props.pipelineStatus).toBe(data.head_pipeline.detailed_status);
      expect(props.assignees).toEqual([data.assignee]);
      expect(props.isMergeRequest).toBe(true);
      expect(props.confidential).toEqual(false);
      expect(props.title).toEqual(data.title);
      expect(props.state).toEqual(data.state);
      expect(props.createdAt).toEqual(data.created_at);
    });
  });
});
