# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an existing release', feature_category: :release_orchestration do
  include GraphqlHelpers
  include Presentable

  let_it_be(:public_user) { create(:user) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:milestone_12_3) { create(:milestone, project: project, title: '12.3') }
  let_it_be(:milestone_12_4) { create(:milestone, project: project, title: '12.4') }

  let_it_be(:tag_name) { 'v1.1.0' }
  let_it_be(:name) { 'Version 7.12.5' }
  let_it_be(:description) { 'Release 7.12.5 :rocket:' }
  let_it_be(:released_at) { '2018-12-10' }
  let_it_be(:created_at) { '2018-11-05' }
  let_it_be(:milestones) { [milestone_12_3, milestone_12_4] }

  let_it_be(:release) do
    create(:release,
      project: project,
      tag: tag_name,
      name: name,
      description: description,
      released_at: Time.parse(released_at).utc,
      created_at: Time.parse(created_at).utc,
      milestones: milestones)
  end

  let(:mutation_name) { :release_update }

  let(:mutation_arguments) do
    {
      projectPath: project.full_path,
      tagName: tag_name
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
      }
      errors
    FIELDS
  end

  let(:update_release) { post_graphql_mutation(mutation, current_user: current_user) }
  let(:mutation_response) { graphql_mutation_response(mutation_name)&.with_indifferent_access }

  let(:expected_attributes) do
    {
      tagName: tag_name,
      name: name,
      description: description,
      releasedAt: Time.parse(released_at).utc.iso8601,
      createdAt: Time.parse(created_at).utc.iso8601,
      milestones: {
        nodes: milestones.map { |m| { title: m.title } }
      }
    }.with_indifferent_access
  end

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
      update_release

      expect(graphql_errors).not_to be_present
    end
  end

  shared_examples 'top-level error with message' do |error_message|
    it 'returns a top-level error with message' do
      update_release

      expect(mutation_response).to be_nil
      expect(graphql_errors.count).to eq(1)
      expect(graphql_errors.first['message']).to eq(error_message)
    end
  end

  shared_examples 'errors-as-data with message' do |error_message|
    it 'returns an error-as-data with message' do
      update_release

      expect(mutation_response[:release]).to be_nil
      expect(mutation_response[:errors].count).to eq(1)
      expect(mutation_response[:errors].first).to match(error_message)
    end
  end

  shared_examples 'updates release fields' do |updates|
    it_behaves_like 'no errors'

    it 'updates the correct field and returns the release' do
      update_release

      expect(mutation_response[:release]).to eq(expected_attributes.merge(updates))
    end
  end

  context 'when the current user has access to update releases' do
    let(:current_user) { developer }

    context 'name' do
      context 'when a new name is provided' do
        let(:mutation_arguments) { super().merge(name: 'Updated name') }

        it_behaves_like 'updates release fields', name: 'Updated name'
      end

      context 'when null is provided' do
        let(:mutation_arguments) { super().merge(name: nil) }

        it_behaves_like 'updates release fields', name: 'v1.1.0'
      end
    end

    context 'description' do
      context 'when a new description is provided' do
        let(:mutation_arguments) { super().merge(description: 'Updated description') }

        it_behaves_like 'updates release fields', description: 'Updated description'
      end

      context 'when null is provided' do
        let(:mutation_arguments) { super().merge(description: nil) }

        it_behaves_like 'updates release fields', description: nil
      end
    end

    context 'releasedAt' do
      context 'when no time zone is provided' do
        let(:mutation_arguments) { super().merge(releasedAt: '2015-05-05') }

        it_behaves_like 'updates release fields', releasedAt: Time.parse('2015-05-05').utc.iso8601
      end

      context 'when a local time zone is provided' do
        let(:mutation_arguments) { super().merge(releasedAt: Time.parse('2015-05-05').in_time_zone('Hawaii').iso8601) }

        it_behaves_like 'updates release fields', releasedAt: Time.parse('2015-05-05').utc.iso8601
      end

      context 'when null is provided' do
        let(:mutation_arguments) { super().merge(releasedAt: nil) }

        it_behaves_like 'top-level error with message', 'if the releasedAt argument is provided, it cannot be null'
      end
    end

    context 'milestones' do
      context 'when a new set of milestones is provided provided' do
        let(:mutation_arguments) { super().merge(milestones: ['12.3']) }

        it_behaves_like 'updates release fields', milestones: { nodes: [{ title: '12.3' }] }
      end

      context 'when an empty array is provided' do
        let(:mutation_arguments) { super().merge(milestones: []) }

        it_behaves_like 'updates release fields', milestones: { nodes: [] }
      end

      context 'when null is provided' do
        let(:mutation_arguments) { super().merge(milestones: nil) }

        it_behaves_like 'top-level error with message', 'if the milestones argument is provided, it cannot be null'
      end

      context 'when a non-existent milestone title is provided' do
        let(:mutation_arguments) { super().merge(milestones: ['not real']) }

        it_behaves_like 'errors-as-data with message', 'Milestone(s) not found: not real'
      end

      context 'when a milestone title from a different project is provided' do
        let(:milestone_in_different_project) { create(:milestone, title: 'milestone in different project') }
        let(:mutation_arguments) { super().merge(milestones: [milestone_in_different_project.title]) }

        it_behaves_like 'errors-as-data with message', 'Milestone(s) not found: milestone in different project'
      end
    end

    context 'validation' do
      context 'when no updated fields are provided' do
        it_behaves_like 'errors-as-data with message', 'params is empty'
      end

      context 'when the tag does not exist' do
        let(:mutation_arguments) { super().merge(tagName: 'not-a-real-tag') }

        it_behaves_like 'errors-as-data with message', 'Tag does not exist'
      end

      context 'when the project does not exist' do
        let(:mutation_arguments) { super().merge(projectPath: 'not/a/real/path') }

        it_behaves_like 'top-level error with message', Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
      end
    end
  end

  context "when the current user doesn't have access to update releases" do
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
