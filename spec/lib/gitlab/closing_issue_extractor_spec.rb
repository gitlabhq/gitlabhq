require 'spec_helper'

describe Gitlab::ClosingIssueExtractor do
  let(:project)   { create(:project) }
  let(:issue)     { create(:issue, project: project) }
  let(:reference) { issue.to_reference }

  subject { described_class.new(project, project.creator) }

  describe "#closed_by_message" do
    context 'with a single reference' do
      it do
        message = "Awesome commit (Closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (closes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "closing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "close #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (fixes #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixed #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fixing #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "fix #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (Resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Awesome commit (resolves #{reference})"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolved #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolving #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "Resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end

      it do
        message = "resolve #{reference}"
        expect(subject.closed_by_message(message)).to eq([issue])
      end
    end

    context 'with multiple references' do
      let(:other_issue) { create(:issue, project: project) }
      let(:third_issue) { create(:issue, project: project) }
      let(:reference2) { other_issue.to_reference }
      let(:reference3) { third_issue.to_reference }

      it 'fetches issues in single line message' do
        message = "Closes #{reference} and fix #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues references in single line message' do
        message = "Closes #{reference}, closes #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches comma-separated issues numbers in single line message' do
        message = "Closes #{reference}, #{reference2} and #{reference3}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue, third_issue])
      end

      it 'fetches issues in multi-line message' do
        message = "Awesome commit (closes #{reference})\nAlso fixes #{reference2}"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue])
      end

      it 'fetches issues in hybrid message' do
        message = "Awesome commit (closes #{reference})\n"\
                  "Also fixing issues #{reference2}, #{reference3} and #4"

        expect(subject.closed_by_message(message)).
            to match_array([issue, other_issue, third_issue])
      end
    end
  end
end
