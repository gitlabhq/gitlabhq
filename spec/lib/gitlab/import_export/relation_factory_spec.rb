require 'spec_helper'

describe Gitlab::ImportExport::RelationFactory, lib: true do
  let(:project) { create(:empty_project) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:user) { create(:user) }
  let(:created_object) do
    described_class.create(relation_sym: relation_sym,
                           relation_hash: relation_hash,
                           members_mapper: members_mapper,
                           user: user,
                           project_id: project.id)
  end

  context 'hook object' do
    let(:relation_sym) { :hooks }
    let(:id) { 999 }
    let(:service_id) { 99 }
    let(:original_project_id) { 8 }
    let(:token) { 'secret' }

    let(:relation_hash) do
      {
        'id' => id,
        'url' => 'https://example.json',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'service_id' => service_id,
        'push_events' => true,
        'issues_events' => false,
        'merge_requests_events' => true,
        'tag_push_events' => false,
        'note_events' => true,
        'enable_ssl_verification' => true,
        'build_events' => false,
        'wiki_page_events' => true,
        'token' => token
      }
    end

    it 'does not have the original ID' do
      expect(created_object.id).not_to eq(id)
    end

    it 'does not have the original service_id' do
      expect(created_object.service_id).not_to eq(service_id)
    end

    it 'does not have the original project_id' do
      expect(created_object.project_id).not_to eq(original_project_id)
    end

    it 'has the new project_id' do
      expect(created_object.project_id).to eq(project.id)
    end

    it 'has a token' do
      expect(created_object.token).to eq(token)
    end

    context 'original service exists' do
      let(:service_id) { Service.create(project: project).id }

      it 'does not have the original service_id' do
        expect(created_object.service_id).not_to eq(service_id)
      end
    end
  end

  # Mocks an ActiveRecordish object with the dodgy columns
  class FooModel
    include ActiveModel::Model

    def initialize(params)
      params.each { |key, value| send("#{key}=", value) }
    end

    def values
      instance_variables.map { |ivar| instance_variable_get(ivar) }
    end
  end

  # `project_id`, `described_class.USER_REFERENCES`, noteable_id, target_id, and some project IDs are already
  # re-assigned by described_class.
  context 'Potentially hazardous foreign keys' do
    let(:relation_sym) { :hazardous_foo_model }
    let(:relation_hash) do
      {
        'service_id' => 99,
        'moved_to_id' => 99,
        'namespace_id' => 99,
        'ci_id' => 99,
        'random_project_id' => 99,
        'random_id' => 99,
        'milestone_id' => 99,
        'project_id' => 99,
        'user_id' => 99,
      }
    end

    class HazardousFooModel < FooModel
      attr_accessor :service_id, :moved_to_id, :namespace_id, :ci_id, :random_project_id, :random_id, :milestone_id, :project_id
    end

    it 'does not preserve any foreign key IDs' do
      expect(created_object.values).not_to include(99)
    end
  end

  context 'Project references' do
    let(:relation_sym) { :project_foo_model }
    let(:relation_hash) do
      Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES.map { |ref| { ref => 99 } }.inject(:merge)
    end

    class ProjectFooModel < FooModel
      attr_accessor(*Gitlab::ImportExport::RelationFactory::PROJECT_REFERENCES)
    end

    it 'does not preserve any project foreign key IDs' do
      expect(created_object.values).not_to include(99)
    end
  end
end
