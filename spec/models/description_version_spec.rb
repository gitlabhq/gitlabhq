# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DescriptionVersion do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }

  describe 'associations' do
    it { is_expected.to belong_to :issue }
    it { is_expected.to belong_to :merge_request }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:namespace) }

    describe 'exactly_one_issuable' do
      using RSpec::Parameterized::TableSyntax

      subject { described_class.new(issue: test_issue, merge_request: test_merge_request).valid? }

      where(:test_issue, :test_merge_request, :valid?) do
        nil         | ref(:merge_request) | true
        ref(:issue) | nil                 | true
        nil         | nil                 | false
        ref(:issue) | ref(:merge_request) | false
      end

      with_them do
        it { is_expected.to eq(valid?) }
      end
    end
  end

  describe 'ensure_namespace_id' do
    context 'when version belongs to a project issue' do
      let(:version) { described_class.new(issue: issue) }

      it 'sets the namespace id from the issue namespace id' do
        expect(version.namespace_id).to be_nil

        version.valid?

        expect(version.namespace_id).to eq(issue.namespace.id)
      end

      context 'when namespace_id is 0' do
        before do
          version.namespace_id = 0
        end

        it 'sets the namespace id from the issue namespace id' do
          expect(version.namespace_id).to eq(0)

          version.valid?

          expect(version.namespace_id).to eq(issue.namespace.id)
        end
      end
    end

    context 'when version belongs to a group issue' do
      let(:issue) { create(:issue, :group_level, namespace: group) }
      let(:version) { described_class.new(issue: issue) }

      it 'sets the namespace id from the issue namespace id' do
        expect(version.namespace_id).to be_nil

        version.valid?

        expect(version.namespace_id).to eq(issue.namespace.id)
      end
    end

    context 'when version belongs to a merge request' do
      let(:version) { described_class.new(merge_request: merge_request) }

      it 'sets the namespace id from the merge request project namespace id' do
        expect(version.namespace_id).to be_nil

        version.valid?

        expect(version.namespace_id).to eq(merge_request.source_project.project_namespace_id)
      end
    end
  end
end
