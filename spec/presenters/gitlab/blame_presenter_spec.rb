# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BlamePresenter do
  let(:project) { create(:project, :repository) }
  let(:path) { 'files/ruby/popen.rb' }
  let(:commit) { project.commit('master') }
  let(:blob) { project.repository.blob_at(commit.id, path) }
  let(:blame) { Gitlab::Blame.new(blob, commit) }

  subject { described_class.new(blame, project: project, path: path) }

  it 'precalculates necessary data on init' do
    expect_any_instance_of(described_class)
      .to receive(:precalculate_data_by_commit!)
      .and_call_original

    subject
  end

  describe '#groups' do
    it 'delegates #groups call to the blame' do
      expect(blame).to receive(:groups).and_call_original

      subject.groups
    end
  end

  describe '#commit_data' do
    it 'has the data necessary to render the view' do
      commit = blame.groups.first[:commit]
      data = subject.commit_data(commit)

      aggregate_failures do
        expect(data.author_avatar.to_s).to include('src="https://www.gravatar.com/')
        expect(data.age_map_class).to include('blame-commit-age-')
        expect(data.commit_link.to_s).to include '913c66a37b4a45b9769037c55c2d238bd0942d2e">Files, encoding and much more</a>'
        expect(data.commit_author_link.to_s).to include('<a class="commit-author-link" href=')
        expect(data.project_blame_link.to_s).to include('<a title="View blame prior to this change"')
        expect(data.time_ago_tooltip.to_s).to include('data-container="body">Feb 27, 2014</time>')
      end
    end
  end
end
