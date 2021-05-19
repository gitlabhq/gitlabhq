# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Releases::Source do
  let_it_be(:project) { create(:project, :repository, name: 'finance-cal') }

  let(:tag_name) { 'v1.0' }

  describe '.all' do
    subject { described_class.all(project, tag_name) }

    it 'returns all formats of sources' do
      expect(subject.map(&:format))
        .to match_array(Gitlab::Workhorse::ARCHIVE_FORMATS)
    end
  end

  describe '#url' do
    subject { source.url }

    let(:source) do
      described_class.new(project: project, tag_name: tag_name, format: format)
    end

    let(:format) { 'zip' }

    it 'returns zip archived source url' do
      is_expected
        .to eq("#{project.web_url}/-/archive/v1.0/finance-cal-v1.0.zip")
    end

    context 'when ref is directory structure' do
      let(:tag_name) { 'beta/v1.0' }

      it 'converts slash to dash' do
        is_expected
          .to eq("#{project.web_url}/-/archive/beta/v1.0/finance-cal-beta-v1.0.zip")
      end
    end
  end
end
