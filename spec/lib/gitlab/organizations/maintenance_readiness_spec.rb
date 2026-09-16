# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Organizations::MaintenanceReadiness, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }

  subject(:ready) { described_class.new(organization).ready? }

  describe '#ready?' do
    context 'when there are no active batched background migrations' do
      it { is_expected.to be(true) }

      it 'ignores non-active migrations' do
        create(:batched_background_migration, :paused)
        create(:batched_background_migration, :finished)
        create(:batched_background_migration, :finalized)

        expect(ready).to be(true)
      end
    end

    context 'when there is an active batched background migration' do
      Gitlab::Database.database_base_models.each do |name, model|
        context "on the #{name} database" do
          before do
            skip "#{name} database is not configured" unless Gitlab::Database.has_database?(name)

            Gitlab::Database::SharedModel.using_connection(model.connection) do
              create(:batched_background_migration, :active)
            end
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end
end
