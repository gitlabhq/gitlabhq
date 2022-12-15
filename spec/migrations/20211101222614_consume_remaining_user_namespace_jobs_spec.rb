# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ConsumeRemainingUserNamespaceJobs, feature_category: :subgroups do
  let(:namespaces) { table(:namespaces) }
  let!(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org', type: nil) }

  context 'when Namespaces with nil `type` still exist' do
    it 'steals sidekiq jobs from BackfillUserNamespace background migration' do
      expect(Gitlab::BackgroundMigration).to receive(:steal).with('BackfillUserNamespace')

      migrate!
    end

    it 'migrates namespaces without type' do
      expect { migrate! }.to change { namespaces.where(type: 'User').count }.from(0).to(1)
    end
  end
end
