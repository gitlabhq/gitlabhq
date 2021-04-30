# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LearnGitlab::Project do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:learn_gitlab_project) { create(:project, name: LearnGitlab::Project::PROJECT_NAME) }
  let_it_be(:learn_gitlab_board) { create(:board, project: learn_gitlab_project, name: LearnGitlab::Project::BOARD_NAME) }
  let_it_be(:learn_gitlab_label) { create(:label, project: learn_gitlab_project, name: LearnGitlab::Project::LABEL_NAME) }

  before do
    learn_gitlab_project.add_developer(current_user)
  end

  describe '.available?' do
    using RSpec::Parameterized::TableSyntax

    where(:project, :board, :label, :expected_result) do
      nil  | nil  | nil  | nil
      nil  | nil  | true | nil
      nil  | true | nil  | nil
      nil  | true | true | nil
      true | nil  | nil  | nil
      true | nil  | true | nil
      true | true | nil  | nil
      true | true | true | true
    end

    with_them do
      before do
        allow_next_instance_of(described_class) do |learn_gitlab|
          allow(learn_gitlab).to receive(:project).and_return(project)
          allow(learn_gitlab).to receive(:board).and_return(board)
          allow(learn_gitlab).to receive(:label).and_return(label)
        end
      end

      subject { described_class.new(current_user).available? }

      it { is_expected.to be expected_result }
    end
  end

  describe '.project' do
    subject { described_class.new(current_user).project }

    it { is_expected.to eq learn_gitlab_project }
  end

  describe '.board' do
    subject { described_class.new(current_user).board }

    it { is_expected.to eq learn_gitlab_board }
  end

  describe '.label' do
    subject { described_class.new(current_user).label }

    it { is_expected.to eq learn_gitlab_label }
  end
end
