# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::FixMergeRequestDiffCommitUsers do
  let(:migration) { described_class.new }

  describe '#perform' do
    context 'when the project exists' do
      it 'does nothing' do
        project = create(:project)

        expect { migration.perform(project.id) }.not_to raise_error
      end
    end

    context 'when the project does not exist' do
      it 'does nothing' do
        expect { migration.perform(-1) }.not_to raise_error
      end
    end
  end
end
# rubocop: enable RSpec/FactoriesInMigrationSpecs
