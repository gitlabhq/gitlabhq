require 'spec_helper'

describe Banzai::Pipeline::ReferenceUnfoldPipeline do
  let(:text) { 'some text' }
  let(:project) { create(:project) }
  let(:objects) { [] }

  let(:result) do
    described_class.to_html(text, project: project, objects: objects)
  end

  context 'invalid initializers' do
    subject { -> { result } }

    context 'project context is invalid' do
      let(:project) { nil }
      it { is_expected.to raise_error StandardError, /No valid project/ }
    end

    context 'objects context is invalid' do
      let(:objects) { ['issue'] }
      it { is_expected.to raise_error StandardError, /No `to_reference` method/ }
    end
  end

  context 'multiple issues and merge requests referenced' do
    subject { result }

    let(:main_project) { create(:project) }

    let(:issue_first) { create(:issue, project: main_project) }
    let(:issue_second) { create(:issue, project: main_project) }
    let(:merge_request) { create(:merge_request, source_project: main_project) }

    let(:objects) { [issue_first, issue_second, merge_request] }

    context 'plain text description' do
      let(:text) { 'Description that references #1, #2 and !1' }

      it { is_expected.to include issue_first.to_reference(project) }
      it { is_expected.to include issue_second.to_reference(project) }
      it { is_expected.to include merge_request.to_reference(project) }
    end

    context 'description with ignored elements' do
      let(:text) do
        <<-EOF
          Hi. This references #1, but not `#2`
          <pre>and not !1</pre>
        EOF
      end


      it { is_expected.to include issue_first.to_reference(project) }
      it { is_expected.to_not include issue_second.to_reference(project) }
      it { is_expected.to_not include merge_request.to_reference(project) }
    end
  end
end
