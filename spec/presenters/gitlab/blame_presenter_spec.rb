# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BlamePresenter do
  let(:project) { create(:project, :repository) }
  let(:path) { 'files/ruby/popen.rb' }
  let(:commit) { project.commit('master') }
  let(:blob) { project.repository.blob_at(commit.id, path) }
  let(:blame) { Gitlab::Blame.new(blob, commit) }
  let(:page) { 1 }

  subject { described_class.new(blame, project: project, path: path, page: page) }

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

  describe '#first_line' do
    it 'delegates #first_line call to the blame' do
      expect(blame).to receive(:first_line).at_least(:once).and_call_original

      subject.first_line
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
        expect(data.time_ago_tooltip.to_s).to include('data-container="body">Feb 27, 2014</time>')
      end
    end

    context 'renamed file' do
      let(:path) { 'files/plain_text/renamed' }
      let(:commit) { project.commit('blame-on-renamed') }

      it 'does not generate link to previous blame on initial commit' do
        commit = blame.groups[0][:commit]
        data = subject.commit_data(commit)

        expect(data.project_blame_link.to_s).to eq('')
      end

      it 'generates link link to previous blame' do
        commit = blame.groups[1][:commit]
        data = subject.commit_data(commit)

        expect(data.project_blame_link.to_s).to include('<a title="View blame prior to this change"')
        expect(data.project_blame_link.to_s).to include('/blame/405a45736a75e439bb059e638afaa9a3c2eeda79/files/plain_text/initial-commit')
      end
    end
  end

  describe '#groups_commit_data' do
    shared_examples 'groups_commit_data' do
      it 'combines group and commit data' do
        data = subject.groups_commit_data

        aggregate_failures do
          expect(data.size).to eq 18
          expect(data.first[:commit].sha).to eq("913c66a37b4a45b9769037c55c2d238bd0942d2e")
          expect(data.first[:lines].size).to eq 3
          expect(data.first[:commit_data].author_avatar).to include('src="https://www.gravatar.com/')
        end
      end
    end

    it_behaves_like 'groups_commit_data'

    context 'when page is not sent as attribute' do
      subject { described_class.new(blame, project: project, path: path) }

      it_behaves_like 'groups_commit_data'
    end

    context 'when project is not sent as attribute' do
      subject { described_class.new(blame, path: path, page: 1) }

      it_behaves_like 'groups_commit_data'
    end
  end
end
