# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::BasicProjectDetails, feature_category: :api do
  let_it_be(:project_with_repository_restriction) { create(:project, :public, :repository_private) }
  let(:member_user) { project_with_repository_restriction.first_owner }

  subject(:output) { described_class.new(project, current_user: current_user).as_json }

  describe '#default_branch' do
    let(:current_user) { member_user }
    let(:project) { project_with_repository_restriction }

    it 'delegates to Project#default_branch_or_main' do
      expect(project).to receive(:default_branch_or_main).twice.and_call_original

      expect(output).to include(default_branch: project.default_branch_or_main)
    end

    context 'anonymous user' do
      let(:current_user) { nil }

      it 'is not included' do
        expect(output).not_to include(:default_branch)
      end
    end
  end

  describe '#readme_url #forks_count' do
    using RSpec::Parameterized::TableSyntax
    let_it_be(:non_member_user) { create(:user) } # Creates a fresh user that is why it is not the member of the project

    context 'public project with repository is accessible by the user' do
      let_it_be(:project_without_restriction) { create(:project, :public) }

      where(:current_user, :project) do
        ref(:member_user)     | ref(:project_without_restriction)
        ref(:non_member_user) | ref(:project_without_restriction)
        nil                   | ref(:project_without_restriction)
        ref(:member_user)     | ref(:project_with_repository_restriction)
      end

      with_them do
        it 'exposes readme_url and forks_count' do
          expect(output).to include readme_url: project.readme_url, forks_count: project.forks_count
        end
      end
    end

    context 'public project with repository is not accessible by the user' do
      where(:current_user, :project) do
        ref(:non_member_user) | ref(:project_with_repository_restriction)
        nil                   | ref(:project_with_repository_restriction)
      end

      with_them do
        it 'does not expose readme_url and forks_count' do
          expect(output).not_to include :readme_url, :forks_count
        end
      end
    end
  end

  describe '#repository_storage' do
    let_it_be(:project) { build(:project, :public) }

    context 'with anonymous user' do
      let_it_be(:current_user) { nil }

      it 'is not included' do
        expect(output).not_to include(:repository_storage)
      end
    end

    context 'with normal user' do
      let_it_be(:current_user) { create(:user) }

      it 'is not included' do
        expect(output).not_to include(:repository_storage)
      end
    end

    context 'with admin user' do
      let_it_be(:current_user) { create(:user, :admin) }

      it 'is included', :enable_admin_mode do
        expect(output).to include repository_storage: project.repository_storage
      end
    end
  end
end
