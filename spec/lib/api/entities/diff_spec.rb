# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Entities::Diff, feature_category: :source_code_management do
  subject(:json) { entity.as_json }

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }
  let_it_be(:diff) { repository.diff('HEAD~1', 'HEAD').first }

  let(:entity) { described_class.new(diff, options) }
  let(:options) { {} }

  it 'returns expected data' do
    expect(entity.as_json).to eq(
      {
        diff: diff.diff,
        new_path: diff.new_path,
        old_path: diff.old_path,
        a_mode: diff.a_mode,
        b_mode: diff.b_mode,
        new_file: diff.new_file?,
        renamed_file: diff.renamed_file?,
        deleted_file: diff.deleted_file?,
        generated_file: diff.generated?
      }
    )
  end

  context 'when enable_unidiff option is set' do
    let(:options) { { enable_unidiff: true } }

    it 'returns expected data' do
      expect(entity.as_json).to include(diff: diff.unidiff)
    end
  end

  context 'when enable_unidiff option is false' do
    let(:options) { { enable_unidiff: false } }

    it 'returns expected data' do
      expect(entity.as_json).to include(diff: diff.diff)
    end
  end
end
