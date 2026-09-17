# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestWidgetCommitEntity do
  let_it_be(:project) { create(:project, :small_repo) }
  let(:commit) { project.commit }
  let(:request) { double('request') }

  let(:entity) do
    described_class.new(commit, request: request)
  end

  context 'as json' do
    subject { entity.as_json }

    it 'returns commit attributes', :aggregate_failures do
      expect(subject[:message]).to eq(commit.safe_message)
      expect(subject[:short_id]).to eq(commit.short_id)
      expect(subject[:title]).to eq(commit.title)
    end
  end
end
