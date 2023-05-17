# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Creation of a new release', feature_category: :release_orchestration do
  include GraphqlHelpers
  include Presentable

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }
  let_it_be(:public_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }

  let(:mutation_name) { :release_create }

  let(:tag_name) { 'v7.12.5' }
  let(:tag_message) { nil }
  let(:ref) { 'master' }
  let(:name) { 'Version 7.12.5' }
  let(:description) { 'Release 7.12.5 :rocket:' }
  let(:released_at) { '2018-12-10' }
  let(:milestones) { [milestone_12_3.title, milestone_12_4.title] }
  let(:asset_link) { { name: 'An asset link', url: 'https://gitlab.example.com/link', directAssetPath: '/permanent/link', linkType: 'OTHER' } }
  let(:assets) { { links: [asset_link] } }

  let(:mutation_arguments) do
    {
      projectPath: project.full_path,
      tagName: tag_name,
      tagMessage: tag_message,
      ref: ref,
      name: name,
      description: description,
      releasedAt: released_at,
      milestones: milestones,
      assets: assets
    }
  end

  let(:mutation) do
    graphql_mutation(mutation_name, mutation_arguments, <<~FIELDS)
      release {
        tagName
        name
        description
        releasedAt
        createdAt
        milestones {
          nodes {
            title
          }
        }
        assets {
          links {
            nodes {
              name
              url
              linkType
              directAssetUrl
            }
          }
        }
      }
      errors
    FIELDS
  end

  let(:create_release) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  around do |example|
    freeze_time { example.run }
  end

  before do
    project.add_guest(guest)
    project.add_reporter(reporter)
    project.add_developer(developer)

    stub_default_url_options(host: 'www.example.com')
  end

  shared_examples 'no errors' do
    it 'returns no errors' do
      create_release

      expect(graphql_errors).not_to be_present
    end
  end

  shared_examples 'top-level error with message' do |error_message|
    it 'returns a top-level error with message' do
      create_release

      expect(mutation_response).to be_nil
      expect(graphql_errors.count).to eq(1)
      expect(graphql_errors.first['message']).to eq(error_message)
    end
  end

  shared_examples 'errors-as-data with message' do |error_message|
    it 'returns an error-as-data with message' do
      create_release

      expect(mutation_response[:release]).to be_nil
      expect(mutation_response[:errors].count).to eq(1)
      expect(mutation_response[:errors].first).to match(error_message)
    end
  end

  context 'when the current user has access to create releases' do
    let(:current_user) { developer }

    context 'when all available mutation arguments are provided' do
      it_behaves_like 'no errors'

      it 'returns the new release data' do
        create_release

        expected_direct_asset_url = Gitlab::Routing.url_helpers.project_release_url(project, Release.find_by(tag: tag_name)) << "/downloads#{asset_link[:directAssetPath]}"

        expected_attributes = {
          tagName: tag_name,
          name: name,
          description: description,
          releasedAt: Time.parse(released_at).utc.iso8601,
          createdAt: Time.current.utc.iso8601,
          assets: {
            links: {
              nodes: [{
                name: asset_link[:name],
                url: asset_link[:url],
                linkType: asset_link[:linkType],
                directAssetUrl: expected_direct_asset_url
              }]
            }
          },
          milestones: {
            nodes: [
              { title: '12.3' },
              { title: '12.4' }
            ]
          }
        }.with_indifferent_access

        expect(mutation_response[:release]).to eq(expected_attributes)
      end
    end

    context 'when only the required mutation arguments are provided' do
      let(:mutation_arguments) { super().slice(:projectPath, :tagName, :ref) }

      it_behaves_like 'no errors'

      it 'returns the new release data' do
        create_release

        expected_response = {
          tagName: tag_name,
          name: tag_name,
          description: nil,
          releasedAt: Time.current.utc.iso8601,
          createdAt: Time.current.utc.iso8601,
          milestones: {
            nodes: []
          },
          assets: {
            links: {
              nodes: []
            }
          }
        }.with_indifferent_access

        expect(mutation_response[:release]).to eq(expected_response)
      end
    end

    context 'when the provided tag already exists' do
      let(:tag_name) { 'v1.1.0' }

      it_behaves_like 'no errors'

      it 'does not create a new tag' do
        expect { create_release }.not_to change { Project.find_by_id(project.id).repository.tag_count }
      end
    end

    context 'when the provided tag does not already exist' do
      let(:tag_name) { 'v7.12.5-alpha' }

      after do
        project.repository.rm_tag(developer, tag_name)
      end

      it_behaves_like 'no errors'

      it 'creates a new lightweight tag' do
        expect { create_release }.to change { Project.find_by_id(project.id).repository.tag_count }.by(1)
        expect(project.repository.find_tag(tag_name).message).to be_blank
      end

      context 'and tag_message is provided' do
        let(:tag_message) { 'Annotated tag message' }

        it_behaves_like 'no errors'

        it 'creates a new annotated tag with the message' do
          expect { create_release }.to change { Project.find_by_id(project.id).repository.tag_count }.by(1)
          expect(project.repository.find_tag(tag_name).message).to eq(tag_message)
        end
      end
    end

    context 'when a local timezone is provided for releasedAt' do
      let(:released_at) { Time.parse(super()).in_time_zone('Hawaii').iso8601 }

      it_behaves_like 'no errors'

      it 'returns the correct releasedAt date in UTC' do
        create_release

        expect(mutation_response[:release]).to include({ releasedAt: Time.parse(released_at).utc.iso8601 })
      end
    end

    context 'when no releasedAt is provided' do
      let(:mutation_arguments) { super().except(:releasedAt) }

      it_behaves_like 'no errors'

      it 'sets releasedAt to the current time' do
        create_release

        expect(mutation_response[:release]).to include({ releasedAt: Time.current.utc.iso8601 })
      end
    end

    context "when a release asset doesn't include an explicit linkType" do
      let(:asset_link) { super().except(:linkType) }

      it_behaves_like 'no errors'

      it 'defaults the linkType to OTHER' do
        create_release

        returned_asset_link_type = mutation_response.dig(:release, :assets, :links, :nodes, 0, :linkType)

        expect(returned_asset_link_type).to eq('OTHER')
      end
    end

    context "when a release asset doesn't include a directAssetPath" do
      let(:asset_link) { super().except(:directAssetPath) }

      it_behaves_like 'no errors'

      it 'returns the provided url as the directAssetUrl' do
        create_release

        returned_asset_link_type = mutation_response.dig(:release, :assets, :links, :nodes, 0, :directAssetUrl)

        expect(returned_asset_link_type).to eq(asset_link[:url])
      end
    end

    context 'empty milestones' do
      shared_examples 'no associated milestones' do
        it_behaves_like 'no errors'

        it 'creates a release with no associated milestones' do
          create_release

          returned_milestones = mutation_response.dig(:release, :milestones, :nodes)

          expect(returned_milestones.count).to eq(0)
        end
      end

      context 'when the milestones parameter is not provided' do
        let(:mutation_arguments) { super().except(:milestones) }

        it_behaves_like 'no associated milestones'
      end

      context 'when the milestones parameter is null' do
        let(:milestones) { nil }

        it_behaves_like 'no associated milestones'
      end

      context 'when the milestones parameter is an empty array' do
        let(:milestones) { [] }

        it_behaves_like 'no associated milestones'
      end
    end

    context 'validation' do
      context 'when a release is already associated to the specified tag' do
        before do
          create(:release, project: project, tag: tag_name)
        end

        it_behaves_like 'errors-as-data with message', 'Release already exists'
      end

      context "when a provided milestone doesn\'t exist" do
        let(:milestones) { ['a fake milestone'] }

        it_behaves_like 'errors-as-data with message', 'Milestone(s) not found: a fake milestone'
      end

      context "when a provided milestone belongs to a different project than the release" do
        let(:milestone_in_different_project) { create(:milestone, title: 'different milestone') }
        let(:milestones) { [milestone_in_different_project.title] }

        it_behaves_like 'errors-as-data with message', "Milestone(s) not found: different milestone"
      end

      context 'when two release assets share the same name' do
        let(:asset_link_1) { { name: 'My link', url: 'https://example.com/1' } }
        let(:asset_link_2) { { name: 'My link', url: 'https://example.com/2' } }
        let(:assets) { { links: [asset_link_1, asset_link_2] } }

        it_behaves_like 'errors-as-data with message', %r{Validation failed: Links have duplicate values \(My link\)}
      end

      context 'when two release assets share the same URL' do
        let(:asset_link_1) { { name: 'My first link', url: 'https://example.com' } }
        let(:asset_link_2) { { name: 'My second link', url: 'https://example.com' } }
        let(:assets) { { links: [asset_link_1, asset_link_2] } }

        it_behaves_like 'errors-as-data with message', %r{Validation failed: Links have duplicate values \(https://example.com\)}
      end

      context 'when the provided tag name is HEAD' do
        let(:tag_name) { 'HEAD' }

        it_behaves_like 'errors-as-data with message', 'Tag name invalid'
      end

      context 'when the provided tag name is empty' do
        let(:tag_name) { '' }

        it_behaves_like 'errors-as-data with message', 'Tag name invalid'
      end

      context "when the provided tag doesn't already exist, and no ref parameter was provided" do
        let(:ref) { nil }
        let(:tag_name) { 'v7.12.5-beta' }

        it_behaves_like 'errors-as-data with message', 'Ref is not specified'
      end
    end
  end

  context "when the current user doesn't have access to create releases" do
    expected_error_message = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR

    context 'when the current user is a Reporter' do
      let(:current_user) { reporter }

      it_behaves_like 'top-level error with message', expected_error_message
    end

    context 'when the current user is a Guest' do
      let(:current_user) { guest }

      it_behaves_like 'top-level error with message', expected_error_message
    end

    context 'when the current user is a public user' do
      let(:current_user) { public_user }

      it_behaves_like 'top-level error with message', expected_error_message
    end
  end
end
