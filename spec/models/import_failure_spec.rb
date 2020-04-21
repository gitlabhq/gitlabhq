# frozen_string_literal: true

require 'spec_helper'

describe ImportFailure do
  describe 'Scopes' do
    let_it_be(:project) { create(:project) }
    let_it_be(:correlation_id) { 'ABC' }
    let_it_be(:hard_failure) { create(:import_failure, :hard_failure, project: project, correlation_id_value: correlation_id) }
    let_it_be(:soft_failure) { create(:import_failure, :soft_failure, project: project, correlation_id_value: correlation_id) }
    let_it_be(:unrelated_failure) { create(:import_failure, project: project) }

    it 'returns hard failures given a correlation ID' do
      expect(ImportFailure.hard_failures_by_correlation_id(correlation_id)).to eq([hard_failure])
    end

    it 'orders hard failures by newest first' do
      older_failure = hard_failure.dup
      Timecop.freeze(1.day.before(hard_failure.created_at)) do
        older_failure.save!

        expect(ImportFailure.hard_failures_by_correlation_id(correlation_id)).to eq([hard_failure, older_failure])
      end
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:group) }
  end

  describe 'Validations' do
    context 'has no group' do
      before do
        allow(subject).to receive(:group).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:project) }
    end

    context 'has no project' do
      before do
        allow(subject).to receive(:project).and_return(nil)
      end

      it { is_expected.to validate_presence_of(:group) }
    end
  end
end
