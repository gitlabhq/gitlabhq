require 'spec_helper'

describe ProjectPresenter do
  let(:user) { create(:user) }

  describe '#license_short_name' do
    let(:project) { create(:project) }
    let(:presenter) { described_class.new(project, current_user: user) }

    context 'when project.repository has a license_key' do
      it 'returns the nickname of the license if present' do
        allow(project.repository).to receive(:license_key).and_return('agpl-3.0')

        expect(presenter.license_short_name).to eq('GNU AGPLv3')
      end

      it 'returns the name of the license if nickname is not present' do
        allow(project.repository).to receive(:license_key).and_return('mit')

        expect(presenter.license_short_name).to eq('MIT License')
      end
    end

    context 'when project.repository has no license_key but a license_blob' do
      it 'returns LICENSE' do
        allow(project.repository).to receive(:license_key).and_return(nil)

        expect(presenter.license_short_name).to eq('LICENSE')
      end
    end
  end

  describe '#default_view' do
    let(:presenter) { described_class.new(project, current_user: user) }

    context 'user not signed in' do
      let(:user) { nil }

      context 'when repository is empty' do
        let(:project) { create(:project_empty_repo, :public) }

        it 'returns activity if user has repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('activity')
        end

        it 'returns activity if user does not have repository access' do
          allow(project).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end

      context 'when repository is not empty' do
        let(:project) { create(:project, :public, :repository) }

        it 'returns files and readme if user has repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('files')
        end

        it 'returns activity if user does not have repository access' do
          allow(presenter).to receive(:can?).with(nil, :download_code, project).and_return(false)

          expect(presenter.default_view).to eq('activity')
        end
      end
    end

    context 'user signed in' do
      let(:user) { create(:user, :readme) }
      let(:project) { create(:project, :public, :repository) }

      context 'when the user is allowed to see the code' do
        it 'returns the project view' do
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(true)

          expect(presenter.default_view).to eq('readme')
        end
      end

      context 'with wikis enabled and the right policy for the user' do
        before do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
        end

        it 'returns wiki if the user has the right policy' do
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(true)

          expect(presenter.default_view).to eq('wiki')
        end

        it 'returns customize_workflow if the user does not have the right policy' do
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('customize_workflow')
        end
      end

      context 'with issues as a feature available' do
        it 'return issues' do
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('projects/issues/issues')
        end
      end

      context 'with no activity, no wikies and no issues' do
        it 'returns customize_workflow as default' do
          project.project_feature.update_attribute(:issues_access_level, 0)
          allow(presenter).to receive(:can?).with(user, :download_code, project).and_return(false)
          allow(presenter).to receive(:can?).with(user, :read_wiki, project).and_return(false)

          expect(presenter.default_view).to eq('customize_workflow')
        end
      end
    end
  end
end
