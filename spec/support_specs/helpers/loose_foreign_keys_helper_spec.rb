# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKeysHelper, feature_category: :database do
  include described_class

  describe '#process_loose_foreign_key_definitions' do
    let_it_be_with_refind(:runner) { create(:ci_runner) }
    let_it_be(:build) { create(:ci_build, runner: runner) }
    let_it_be(:running_build) { create(:ci_running_build, build: build, runner: runner, project: build.project) }

    let(:definition) do
      Gitlab::Database::LooseForeignKeys.definitions_by_table['ci_runners'].find do |definition|
        definition.from_table == 'p_ci_builds'
      end
    end

    subject(:process) { process_loose_foreign_key_definitions(definitions: [definition], record: runner) }

    before do
      runner.delete
    end

    it 'cleans up the children of the given definitions' do
      expect { process }.to change { build.reload.runner_id }.from(runner.id).to(nil)
    end

    it 'does not clean up the children of other definitions of the parent table' do
      process

      expect(Ci::RunningBuild.exists?(running_build.id)).to be(true)
    end

    context 'when no definitions are given' do
      it 'raises an error' do
        expect { process_loose_foreign_key_definitions(definitions: nil, record: runner) }
          .to raise_error(ArgumentError, 'Expected at least one loose foreign key definition, got nil')
      end
    end
  end
end
