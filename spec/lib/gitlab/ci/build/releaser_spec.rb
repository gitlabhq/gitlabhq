# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Releaser, feature_category: :continuous_integration do
  let(:job) { build(:ci_build, options: { release: config[:release] }) }

  subject(:releaser) { described_class.new(job: job) }

  describe '#script' do
    subject(:script) { releaser.script }

    context 'all nodes' do
      let(:config) do
        {
          release: {
            name: 'Release $CI_COMMIT_SHA',
            description: 'Created using the release-cli $EXTRA_DESCRIPTION',
            tag_name: 'release-$CI_COMMIT_SHA',
            tag_message: 'Annotated tag message',
            ref: '$CI_COMMIT_SHA',
            milestones: %w[m1 m2 m3],
            released_at: '2020-07-15T08:00:00Z',
            assets: {
              links: [
                { name: 'asset1', url: 'https://example.com/assets/1', link_type: 'other', filepath: '/pretty/asset/1' },
                { name: 'asset2', url: 'https://example.com/assets/2' }
              ]
            }
          }
        }
      end

      let(:result_script) do
        'release-cli create --name "Release $CI_COMMIT_SHA" --description "Created using the release-cli $EXTRA_DESCRIPTION" ' \
          '--tag-name "release-$CI_COMMIT_SHA" --tag-message "Annotated tag message" --ref "$CI_COMMIT_SHA" --released-at "2020-07-15T08:00:00Z" ' \
          '--milestone "m1" --milestone "m2" --milestone "m3" --assets-link "{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\",\"filepath\":\"/pretty/asset/1\"}" ' \
          '--assets-link "{\"name\":\"asset2\",\"url\":\"https://example.com/assets/2\"}"'
      end

      it 'generates the script' do
        expect(script).to eq([result_script])
      end

      context 'when the project is a catalog resource' do
        let_it_be(:project) { create(:project, :catalog_resource_with_components) }
        let_it_be(:ci_catalog_resource) { create(:ci_catalog_resource, project: project) }
        let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

        let(:job) { build(:ci_build, pipeline: pipeline, options: { release: config[:release] }) }

        it 'generates glab scripts' do
          expect(script).to eq([
            "if ! command -v glab &> /dev/null; then\n  " \
              "echo \"Error: glab command not found. Please install glab 1.52.0 or higher. Troubleshooting: http://localhost/help/user/project/releases/_index.md#gitlab-cli-version-requirement\"\n  exit 1\nfi\n",
            "if [ \"$(printf \"%s\n%s\" \"1.52.0\" \"$(glab --version | grep -oE '[0-9]+.[0-9]+.[0-9]+')\" | sort -V | head -n1)\" = \"1.52.0\" ]; " \
              "then\n  echo \"Validating glab version. OK\"\nelse\n  echo \"Error: Please use glab 1.52.0 or higher. Troubleshooting: http://localhost/help/user/project/releases/_index.md#gitlab-cli-version-requirement\"\n  exit 1\nfi\n",
            'glab auth login --job-token $CI_JOB_TOKEN --hostname $CI_SERVER_FQDN --api-protocol $CI_SERVER_PROTOCOL',
            'GITLAB_HOST=$CI_SERVER_URL glab -R $CI_PROJECT_PATH release create "release-$CI_COMMIT_SHA" ' \
              '--assets-links "[{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\",\"filepath\":\"/pretty/asset/1\"},{\"name\":\"asset2\",\"url\":\"https://example.com/assets/2\"}]" ' \
              '--milestone "m1,m2,m3" --name "Release $CI_COMMIT_SHA" --notes "Created using the release-cli $EXTRA_DESCRIPTION" ' \
              '--ref "$CI_COMMIT_SHA" --tag-message "Annotated tag message" --released-at "2020-07-15T08:00:00Z" ' \
              '--publish-to-catalog --no-update --no-close-milestone'
          ])
        end

        context 'when the FF ci_release_cli_catalog_publish_option is disabled' do
          before do
            stub_feature_flags(ci_release_cli_catalog_publish_option: false)
          end

          it 'generates the release-cli script' do
            expect(script).to eq([result_script])
          end
        end
      end
    end

    context 'individual nodes' do
      using RSpec::Parameterized::TableSyntax
      links = { links: [{ name: 'asset1', url: 'https://example.com/assets/1', link_type: 'other', filepath: '/pretty/asset/1' }] }

      where(:node_name, :node_value, :result) do
        :name        | 'Release $CI_COMMIT_SHA'         | 'release-cli create --name "Release $CI_COMMIT_SHA"'
        :description | 'Release-cli $EXTRA_DESCRIPTION' | 'release-cli create --description "Release-cli $EXTRA_DESCRIPTION"'
        :tag_name    | 'release-$CI_COMMIT_SHA'         | 'release-cli create --tag-name "release-$CI_COMMIT_SHA"'
        :tag_message | 'Annotated tag message'          | 'release-cli create --tag-message "Annotated tag message"'
        :ref         | '$CI_COMMIT_SHA'                 | 'release-cli create --ref "$CI_COMMIT_SHA"'
        :milestones  | %w[m1 m2 m3]                     | 'release-cli create --milestone "m1" --milestone "m2" --milestone "m3"'
        :released_at | '2020-07-15T08:00:00Z'           | 'release-cli create --released-at "2020-07-15T08:00:00Z"'
        :assets      | links                            | "release-cli create --assets-link #{links[:links][0].to_json.to_json}"
      end

      with_them do
        let(:config) do
          {
            release: {
              node_name => node_value
            }
          }
        end

        it 'generates the script' do
          expect(script).to eq([result])
        end
      end
    end
  end
end
