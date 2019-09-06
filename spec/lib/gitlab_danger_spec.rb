# frozen_string_literal: true

require 'spec_helper'

describe GitlabDanger do
  let(:gitlab_danger_helper) { nil }

  subject { described_class.new(gitlab_danger_helper) }

  describe '.local_warning_message' do
    it 'returns an informational message with rules that can run' do
      expect(described_class.local_warning_message).to eq('==> Only the following Danger rules can be run locally: changes_size, gemfile, documentation, frozen_string, duplicate_yarn_dependencies, prettier, eslint, database')
    end
  end

  describe '.success_message' do
    it 'returns an informational success message' do
      expect(described_class.success_message).to eq('==> No Danger rule violations!')
    end
  end

  describe '#rule_names' do
    context 'when running locally' do
      it 'returns local only rules' do
        expect(subject.rule_names).to eq(described_class::LOCAL_RULES)
      end
    end

    context 'when running under CI' do
      let(:gitlab_danger_helper) { double('danger_gitlab_helper') }

      it 'returns all rules' do
        expect(subject.rule_names).to eq(described_class::LOCAL_RULES | described_class::CI_ONLY_RULES)
      end
    end
  end

  describe '#html_link' do
    context 'when running locally' do
      it 'returns the same string' do
        str = 'something'

        expect(subject.html_link(str)).to eq(str)
      end
    end

    context 'when running under CI' do
      let(:gitlab_danger_helper) { double('danger_gitlab_helper') }

      it 'returns a HTML link formatted version of the string' do
        str = 'something'
        html_formatted_str = %Q{<a href="#{str}">#{str}</a>}

        expect(gitlab_danger_helper).to receive(:html_link).with(str).and_return(html_formatted_str)

        expect(subject.html_link(str)).to eq(html_formatted_str)
      end
    end
  end

  describe '#ci?' do
    context 'when gitlab_danger_helper is not available' do
      it 'returns false' do
        expect(subject.ci?).to be_falsey
      end
    end

    context 'when gitlab_danger_helper is available' do
      let(:gitlab_danger_helper) { double('danger_gitlab_helper') }

      it 'returns true' do
        expect(subject.ci?).to be_truthy
      end
    end
  end
end
