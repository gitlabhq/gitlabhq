import SidebarStore from '~/sidebar/stores/sidebar_store';
import Mock from './mock_data';
import UsersMockHelper from '../helpers/user_mock_data_helper';

const ASSIGNEE = {
  id: 2,
  name: 'gitlab user 2',
  username: 'gitlab2',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
};

const ANOTHER_ASSINEE = {
  id: 3,
  name: 'gitlab user 3',
  username: 'gitlab3',
  avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
};

const PARTICIPANT = {
  id: 1,
  state: 'active',
  username: 'marcene',
  name: 'Allie Will',
  web_url: 'foo.com',
  avatar_url: 'gravatar.com/avatar/xxx',
};

const PARTICIPANT_LIST = [
  PARTICIPANT,
  { ...PARTICIPANT, id: 2 },
  { ...PARTICIPANT, id: 3 },
];

describe('Sidebar store', function () {
  beforeEach(() => {
    this.store = new SidebarStore({
      currentUser: {
        id: 1,
        name: 'Administrator',
        username: 'root',
        avatar_url: 'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      },
      editable: true,
      rootPath: '/',
      endpoint: '/gitlab-org/gitlab-shell/issues/5.json',
    });
  });

  afterEach(() => {
    SidebarStore.singleton = null;
  });

  it('has default isFetching values', () => {
    expect(this.store.isFetching.assignees).toBe(true);
  });

  it('adds a new assignee', () => {
    this.store.addAssignee(ASSIGNEE);
    expect(this.store.assignees.length).toEqual(1);
  });

  it('removes an assignee', () => {
    this.store.removeAssignee(ASSIGNEE);
    expect(this.store.assignees.length).toEqual(0);
  });

  it('finds an existent assignee', () => {
    let foundAssignee;

    this.store.addAssignee(ASSIGNEE);
    foundAssignee = this.store.findAssignee(ASSIGNEE);
    expect(foundAssignee).toBeDefined();
    expect(foundAssignee).toEqual(ASSIGNEE);
    foundAssignee = this.store.findAssignee(ANOTHER_ASSINEE);
    expect(foundAssignee).toBeUndefined();
  });

  it('removes all assignees', () => {
    this.store.removeAllAssignees();
    expect(this.store.assignees.length).toEqual(0);
  });

  it('sets participants data', () => {
    expect(this.store.participants.length).toEqual(0);

    this.store.setParticipantsData({
      participants: PARTICIPANT_LIST,
    });

    expect(this.store.isFetching.participants).toEqual(false);
    expect(this.store.participants.length).toEqual(PARTICIPANT_LIST.length);
  });

  it('sets subcriptions data', () => {
    expect(this.store.subscribed).toEqual(null);

    this.store.setSubscriptionsData({
      subscribed: true,
    });

    expect(this.store.isFetching.subscriptions).toEqual(false);
    expect(this.store.subscribed).toEqual(true);
  });

  it('set assigned data', () => {
    const users = {
      assignees: UsersMockHelper.createNumberRandomUsers(3),
    };

    this.store.setAssigneeData(users);
    expect(this.store.isFetching.assignees).toBe(false);
    expect(this.store.assignees.length).toEqual(3);
  });

  it('sets fetching state', () => {
    expect(this.store.isFetching.participants).toEqual(true);

    this.store.setFetchingState('participants', false);

    expect(this.store.isFetching.participants).toEqual(false);
  });

  it('sets loading state', () => {
    this.store.setLoadingState('assignees', true);

    expect(this.store.isLoading.assignees).toEqual(true);
  });

  it('set time tracking data', () => {
    this.store.setTimeTrackingData(Mock.time);
    expect(this.store.timeEstimate).toEqual(Mock.time.time_estimate);
    expect(this.store.totalTimeSpent).toEqual(Mock.time.total_time_spent);
    expect(this.store.humanTimeEstimate).toEqual(Mock.time.human_time_estimate);
    expect(this.store.humanTotalTimeSpent).toEqual(Mock.time.human_total_time_spent);
  });

  it('set autocomplete projects', () => {
    const projects = [{ id: 0 }];
    this.store.setAutocompleteProjects(projects);

    expect(this.store.autocompleteProjects).toEqual(projects);
  });

  it('sets subscribed state', () => {
    expect(this.store.subscribed).toEqual(null);

    this.store.setSubscribedState(true);

    expect(this.store.subscribed).toEqual(true);
  });

  it('set move to project ID', () => {
    const projectId = 7;
    this.store.setMoveToProjectId(projectId);

    expect(this.store.moveToProjectId).toEqual(projectId);
  });
});
