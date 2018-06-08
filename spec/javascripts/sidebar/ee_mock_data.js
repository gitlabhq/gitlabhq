import CEMockData from './mock_data';

const RESPONSE_MAP = { ...CEMockData.responseMap };

RESPONSE_MAP.GET['/gitlab-org/gitlab-shell/issues/5.json?serializer=sidebar'] = {
  assignees: [
    {
      name: 'User 0',
      username: 'user0',
      id: 22,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/user0',
    },
    {
      name: 'Marguerite Bartell',
      username: 'tajuana',
      id: 18,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/4852a41fb41616bf8f140d3701673f53?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/tajuana',
    },
    {
      name: 'Laureen Ritchie',
      username: 'michaele.will',
      id: 16,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/e301827eb03be955c9c172cb9a8e4e8a?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/michaele.will',
    },
  ],
  human_time_estimate: null,
  human_total_time_spent: null,
  participants: [
    {
      name: 'User 0',
      username: 'user0',
      id: 22,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/52e4ce24a915fb7e51e1ad3b57f4b00a?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/user0',
    },
    {
      name: 'Marguerite Bartell',
      username: 'tajuana',
      id: 18,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/4852a41fb41616bf8f140d3701673f53?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/tajuana',
    },
    {
      name: 'Laureen Ritchie',
      username: 'michaele.will',
      id: 16,
      state: 'active',
      avatar_url:
        'http: //www.gravatar.com/avatar/e301827eb03be955c9c172cb9a8e4e8a?s=80\u0026d=identicon',
      web_url: 'http: //localhost:3001/michaele.will',
    },
  ],
  subscribed: true,
  time_estimate: 0,
  total_time_spent: 0,
  weight: 3,
};

export default {
  ...CEMockData,
  mediator: {
    ...CEMockData.mediator,
    weightOptions: ['None', 0, 1, 3],
    weightNoneValue: 'None',
  },
  responseMap: RESPONSE_MAP,
};
