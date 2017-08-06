import { storiesOf } from '@storybook/vue';
import * as mrWidget from '../app/assets/javascripts/vue_merge_request_widget/dependencies';
import mockData from '../spec/javascripts/vue_mr_widget/mock_data';

window.gon = window.gon || {};
window.gon.current_user_id = 1;

const author = {
  webUrl: 'http://foo.bar',
  avatarUrl: 'http://gravatar.com/foo',
  name: 'fatihacet',
};

const stories = storiesOf('MR Widget.Deployment', module);

const defaultCombinations = [
  {
    title: 'default',
  },
];

const defaultComponent = {
  template: '<h2 class="error">Component not found</h2>',
};

function makeStories({
  title,
  component = defaultComponent,
  service = {},
  combinations = defaultCombinations,
}) {
  stories.add(title, () => ({
    data() {
      return {
        service,
        component,
      };
    },
    computed: {
      sections() {
        return combinations.map(section => ({
          ...section,
          props: section.props || {},
        }));
      },
    },
    template: `
      <div class="container-fluid container-limited limit-container-width">
        <div class="content" id="content-body">
          <template v-for="section in sections">
            <h3>{{section.title}}</h3>
              <div class="mr-state-widget prepend-top-default">
                <div class="mr-widget-section">
                  <component
                    :is="component"
                    :mr="section.props"
                    :service="service" />
                </div>
              </div>
            </template>
          </div>
        </div>
      </div>
    `,
  }));
}

const metricsMockData = {
  success: true,
  metrics: {
    memory_before: [
      {
        metric: {},
        value: [1495785220.607, '9572875.906976745'],
      },
    ],
    memory_after: [
      {
        metric: {},
        value: [1495787020.607, '4485853.130206379'],
      },
    ],
    memory_values: [
      {
        metric: {},
        values: [
          [1493716685, '4.30859375'],
        ],
      },
    ],
  },
  last_update: '2017-05-02T12:34:49.628Z',
  deployment_time: 1493718485,
};

makeStories({
  title: 'Deployment',
  component: mrWidget.WidgetDeployment,
  service: {
    fetchMetrics: () => new Promise((resolve) => {
      resolve({
        json() {
          return metricsMockData;
        },
      });
    }),
  },
  combinations: [
    {
      title: 'default',
      props: {
        ...mockData,
        deployments: [

        ],
      },
    },
  ],
});
