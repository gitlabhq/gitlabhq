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

const stories = storiesOf('MR Widget.Header', module);

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
                <component
                  :is="component"
                  :mr="section.props"
                  :service="service" />
              </div>
            </template>
          </div>
        </div>
      </div>
    `,
  }));
}

makeStories({
  title: 'Header',
  component: mrWidget.WidgetHeader,
  combinations: [
    {
      title: 'default',
      props: {
        divergedCommitsCount: 12,
        sourceBranch: 'mr-widget-refactor',
        sourceBranchLink: '/foo/bar/mr-widget-refactor',
        targetBranch: 'master',
      },
    },
  ],
});
