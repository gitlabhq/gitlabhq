# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportFailure do
  describe 'Scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:correlation_id) { 'ABC' }
    let_it_be(:hard_failure) { create(:import_failure, :hard_failure, project: project, correlation_id_value: correlation_id) }
    let_it_be(:soft_failure) { create(:import_failure, :soft_failure, project: project, correlation_id_value: correlation_id) }
    let_it_be(:github_import_failure) { create(:import_failure, :github_import_failure, project: project) }
    let_it_be(:unrelated_failure) { create(:import_failure, project: project) }

    it 'returns failures with external_identifiers' do
      expect(described_class.with_external_identifiers).to match_array([github_import_failure])
    end

    it 'returns failures for the given correlation ID' do
      expect(described_class.failures_by_correlation_id(correlation_id)).to match_array([hard_failure, soft_failure])
    end

    it 'returns hard failures for the given correlation ID' do
      expect(described_class.hard_failures_by_correlation_id(correlation_id)).to eq([hard_failure])
    end

    it 'orders hard failures by newest first' do
      older_failure = hard_failure.dup
      travel_to(1.day.before(hard_failure.created_at)) do
        older_failure.save!

        expect(ImportFailure.hard_failures_by_correlation_id(correlation_id)).to eq([hard_failure, older_failure])
      end
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'Validations' do
    let_it_be(:group) { build(:group) }
    let_it_be(:project) { build(:project) }
    let_it_be(:user) { build(:user) }

    context 'has project' do
      before do
        allow(subject).to receive(:project).and_return(project)
      end

      it { is_expected.to validate_absence_of(:group) }
      it { is_expected.to validate_absence_of(:user) }
    end

    context 'has group' do
      before do
        allow(subject).to receive(:group).and_return(group)
      end

      it { is_expected.to validate_absence_of(:project) }
      it { is_expected.to validate_absence_of(:user) }
    end

    context 'has user' do
      before do
        allow(subject).to receive(:user).and_return(user)
      end

      it { is_expected.to validate_absence_of(:project) }
      it { is_expected.to validate_absence_of(:group) }
    end

    describe '#external_identifiers' do
      it { is_expected.to allow_value({ note_id: 234, noteable_id: 345, noteable_type: 'MergeRequest' }).for(:external_identifiers) }
      it { is_expected.not_to allow_value(nil).for(:external_identifiers) }
      it { is_expected.not_to allow_value({ ids: [123] }).for(:external_identifiers) }

      it 'allows up to 3 fields' do
        is_expected.not_to allow_value({
          note_id: 234,
          noteable_id: 345,
          noteable_type: 'MergeRequest',
          object_type: 'pull_request',
          extra_attribute: 'abc'
        }).for(:external_identifiers)
      end
    end
  end
end
