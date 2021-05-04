# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::Project::Sample::RelationFactory do
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, group: group) }
  let(:members_mapper) { double('members_mapper').as_null_object }
  let(:admin) { create(:admin) }
  let(:importer_user) { admin }
  let(:excluded_keys) { [] }
  let(:date_calculator) { instance_double(Gitlab::ImportExport::Project::Sample::DateCalculator) }
  let(:original_project_id) { 8 }
  let(:start_date) { Time.current - 30.days }
  let(:due_date) { Time.current - 20.days }
  let(:created_object) do
    described_class.create( # rubocop:disable Rails/SaveBang
      relation_sym: relation_sym,
      relation_hash: relation_hash,
      relation_index: 1,
      object_builder: Gitlab::ImportExport::Project::ObjectBuilder,
      members_mapper: members_mapper,
      user: importer_user,
      importable: project,
      excluded_keys: excluded_keys,
      date_calculator: date_calculator
    )
  end

  context 'issue object' do
    let(:relation_sym) { :issues }
    let(:id) { 999 }

    let(:relation_hash) do
      {
        'id' => id,
        'title' => 'Necessitatibus magnam qui at velit consequatur perspiciatis.',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'description' => 'Molestiae corporis magnam et fugit aliquid nulla quia.',
        'state' => 'closed',
        'position' => 0,
        'confidential' => false,
        'due_date' => due_date
      }
    end

    before do
      allow(date_calculator).to receive(:closest_date_to_average) { Time.current - 10.days }
      allow(date_calculator).to receive(:calculate_by_closest_date_to_average)
    end

    it 'correctly updated due date', :aggregate_failures do
      expect(date_calculator).to receive(:calculate_by_closest_date_to_average)
        .with(relation_hash['due_date']).and_return(due_date - 10.days)

      expect(created_object.due_date).to eq((due_date - 10.days).to_date)
    end
  end

  context 'milestone object' do
    let(:relation_sym) { :milestones }
    let(:id) { 1001 }

    let(:relation_hash) do
      {
        'id' => id,
        'title' => 'v3.0',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'description' => 'Rerum at autem exercitationem ea voluptates harum quam placeat.',
        'state' => 'closed',
        'start_date' => start_date,
        'due_date' => due_date
      }
    end

    before do
      allow(date_calculator).to receive(:closest_date_to_average).twice { Time.current - 10.days }
      allow(date_calculator).to receive(:calculate_by_closest_date_to_average).twice
    end

    it 'correctly updated due date', :aggregate_failures do
      expect(date_calculator).to receive(:calculate_by_closest_date_to_average)
        .with(relation_hash['due_date']).and_return(due_date - 10.days)

      expect(created_object.due_date).to eq((due_date - 10.days).to_date)
    end

    it 'correctly updated start date', :aggregate_failures do
      expect(date_calculator).to receive(:calculate_by_closest_date_to_average)
        .with(relation_hash['start_date']).and_return(start_date - 20.days)

      expect(created_object.start_date).to eq((start_date - 20.days).to_date)
    end
  end

  context 'milestone object' do
    let(:relation_sym) { :milestones }
    let(:id) { 1001 }

    let(:relation_hash) do
      {
        'id' => id,
        'title' => 'v3.0',
        'project_id' => original_project_id,
        'created_at' => '2016-08-12T09:41:03.462Z',
        'updated_at' => '2016-08-12T09:41:03.462Z',
        'description' => 'Rerum at autem exercitationem ea voluptates harum quam placeat.',
        'state' => 'closed',
        'start_date' => start_date,
        'due_date' => due_date
      }
    end

    before do
      allow(date_calculator).to receive(:closest_date_to_average).twice { Time.current - 10.days }
      allow(date_calculator).to receive(:calculate_by_closest_date_to_average).twice
    end

    it 'correctly updated due date', :aggregate_failures do
      expect(date_calculator).to receive(:calculate_by_closest_date_to_average)
        .with(relation_hash['due_date']).and_return(due_date - 10.days)

      expect(created_object.due_date).to eq((due_date - 10.days).to_date)
    end

    it 'correctly updated start date', :aggregate_failures do
      expect(date_calculator).to receive(:calculate_by_closest_date_to_average)
        .with(relation_hash['start_date']).and_return(start_date - 20.days)

      expect(created_object.start_date).to eq((start_date - 20.days).to_date)
    end
  end

  context 'hook object' do
    let(:relation_sym) { :hooks }
    let(:id) { 999 }
    let(:service_id) { 99 }
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
        'confidential_issues_events' => false,
        'merge_requests_events' => true,
        'tag_push_events' => false,
        'note_events' => true,
        'enable_ssl_verification' => true,
        'job_events' => false,
        'wiki_page_events' => true,
        'token' => token
      }
    end

    it 'does not calculate the closest date to average' do
      expect(date_calculator).not_to receive(:calculate_by_closest_date_to_average)
    end
  end
end
