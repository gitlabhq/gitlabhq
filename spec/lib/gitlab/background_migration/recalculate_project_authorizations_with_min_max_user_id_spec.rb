# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateProjectAuthorizationsWithMinMaxUserId, schema: 20200204113224 do
  let(:users_table) { table(:users) }
  let(:min) { 1 }
  let(:max) { 5 }

  before do
    min.upto(max) do |i|
      users_table.create!(id: i, email: "user#{i}@example.com", projects_limit: 10)
    end
  end

  describe '#perform' do
    it 'initializes Users::RefreshAuthorizedProjectsService with correct users' do
      min.upto(max) do |i|
        user = User.find(i)
        expect(Users::RefreshAuthorizedProjectsService).to(
          receive(:new).with(user, any_args).and_call_original)
      end

      described_class.new.perform(min, max)
    end

    it 'executes Users::RefreshAuthorizedProjectsService' do
      expected_call_counts = max - min + 1

      service = instance_double(Users::RefreshAuthorizedProjectsService)
      expect(Users::RefreshAuthorizedProjectsService).to(
        receive(:new).exactly(expected_call_counts).times.and_return(service))
      expect(service).to receive(:execute).exactly(expected_call_counts).times

      described_class.new.perform(min, max)
    end
  end
end
