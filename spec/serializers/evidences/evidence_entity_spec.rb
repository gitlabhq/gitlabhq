# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::EvidenceEntity do
  let_it_be(:project) { create(:project) }

  let(:release) { create(:release, project: project) }
  let(:evidence) { build(:evidence, release: release) }
  let(:schema_file) { 'evidences/evidence' }

  subject { described_class.new(evidence).as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:release)
  end

  context 'when a release is associated to a milestone' do
    let(:milestone) { create(:milestone, project: project) }
    let(:release) { create(:release, project: project, milestones: [milestone]) }

    context 'when a milestone has no issue associated with it' do
      it 'creates a valid JSON object' do
        expect(subject[:release][:milestones].first[:issues]).to be_empty
        expect(subject.to_json).to match_schema(schema_file)
      end
    end

    context 'when a milestone has no description' do
      let(:milestone) { create(:milestone, project: project, description: nil) }

      it 'creates a valid JSON object' do
        expect(subject[:release][:milestones].first[:description]).to be_nil
        expect(subject.to_json).to match_schema(schema_file)
      end
    end

    context 'when a milestone has no due_date' do
      let(:milestone) { create(:milestone, project: project, due_date: nil) }

      it 'creates a valid JSON object' do
        expect(subject[:release][:milestones].first[:due_date]).to be_nil
        expect(subject.to_json).to match_schema(schema_file)
      end
    end

    context 'when a milestone has an issue' do
      context 'when the issue has no description' do
        let(:issue) { create(:issue, project: project, description: nil, state: 'closed') }

        before do
          milestone.issues << issue
        end

        it 'creates a valid JSON object' do
          expect(subject[:release][:milestones].first[:issues].first[:title]).to be_present
          expect(subject.to_json).to match_schema(schema_file)
        end
      end
    end
  end

  context 'when a release is not associated to any milestone' do
    it 'creates a valid JSON object' do
      expect(subject[:release][:milestones]).to be_empty
      expect(subject.to_json).to match_schema(schema_file)
    end
  end
end
