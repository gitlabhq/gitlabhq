require 'spec_helper'

describe Gitlab::Gfm::ReferenceUnfolder do
  let(:text) { 'some text' }
  let(:old_project) { create(:project) }
  let(:new_project) { create(:project) }

  describe '#unfold' do
    subject { described_class.new(text, old_project).unfold(new_project) }

    context 'multiple issues and merge requests referenced' do
      let!(:issue_first) { create(:issue, project: old_project) }
      let!(:issue_second) { create(:issue, project: old_project) }
      let!(:merge_request) { create(:merge_request, source_project: old_project) }

      context 'plain text description' do
        let(:text) { 'Description that references #1, #2 and !1' }

        it { is_expected.to include issue_first.to_reference(new_project) }
        it { is_expected.to include issue_second.to_reference(new_project) }
        it { is_expected.to include merge_request.to_reference(new_project) }
      end

      context 'description with ignored elements' do
        let(:text) do
          "Hi. This references #1, but not `#2`\n" +
          '<pre>and not !1</pre>'
        end

        it { is_expected.to include issue_first.to_reference(new_project) }
        it { is_expected.to_not include issue_second.to_reference(new_project) }
        it { is_expected.to_not include merge_request.to_reference(new_project) }
      end

      context 'description ambigous elements' do
        let(:url) { 'http://gitlab.com/#1' }
        let(:text) { "This references #1, but not #{url}" }

        it { is_expected.to include url }
      end
    end
  end
end
