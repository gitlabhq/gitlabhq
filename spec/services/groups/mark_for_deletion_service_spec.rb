# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::MarkForDeletionService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let(:params) { { param: true } }
  let(:service) { described_class.new(group, user, params) }

  context 'when in FOSS', unless: Gitlab.ee? do
    describe '#execute' do
      context 'when async is true' do
        it 'executes the Groups::DestroyService with the same parameters asychronously' do
          expect_next_instance_of(Groups::DestroyService, group, user, params) do |destroy_service|
            expect(destroy_service).to receive(:async_execute)
          end

          service.execute
        end
      end

      context 'when async is false' do
        it 'executes the Groups::DestroyService with the same parameters sychronously' do
          expect_next_instance_of(Groups::DestroyService, group, user, params) do |destroy_service|
            expect(destroy_service).to receive(:execute)
          end

          service.execute(async: false)
        end
      end
    end
  end
end
