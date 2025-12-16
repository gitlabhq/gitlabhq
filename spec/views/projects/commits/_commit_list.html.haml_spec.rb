# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/commits/_commit_list.html.haml', feature_category: :source_code_management do
  let(:project) { build_stubbed(:project) }
  let(:commits) { Array.new(2) { Gitlab::Git::Commit.new(project.repository, build(:gitaly_commit)) } }

  before do
    controller.prepend_view_path('app/views/projects')

    assign(:project, project)
    assign(:commits, commits)
    assign(:total_commit_count, commits.size)
    assign(:ref, 'master')

    allow(view).to receive(:current_user).and_return(nil)
  end

  context 'when @hidden_commit_count is nil' do
    before do
      assign(:hidden_commit_count, nil)
    end

    it 'renders without NoMethodError' do
      expect { render }.not_to raise_error
    end

    it 'does not show hidden commits message' do
      render

      expect(rendered).not_to include('additional commits have been omitted')
    end
  end

  context 'when @hidden_commit_count is greater than 0' do
    before do
      assign(:hidden_commit_count, 10)
    end

    it 'renders without error' do
      expect { render }.not_to raise_error
    end

    it 'shows hidden commits message' do
      render

      expect(rendered).to include('10 additional commits have been omitted')
    end
  end
end
