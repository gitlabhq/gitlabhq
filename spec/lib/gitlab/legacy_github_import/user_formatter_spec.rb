# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::UserFormatter, feature_category: :importers do
  let_it_be_with_reload(:project) do
    create(
      :project, :in_group,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled,
      import_type: 'gitea'
    )
  end

  # GitLab's system ghost user - used as mapping for Gitea ghost user
  let_it_be(:gitlab_ghost_user) { Users::Internal.for_organization(project.organization).ghost }

  let(:source_user_mapper) do
    Gitlab::Import::SourceUserMapper.new(
      namespace: project.root_ancestor,
      import_type: project.import_type,
      source_hostname: 'https://gitea.com'
    )
  end

  let(:client) { instance_double(Gitlab::LegacyGithubImport::Client) }
  let(:gitea_user) { { id: 123456, login: 'octocat', full_name: 'Git Tea', email: 'user@email.com' } }
  let(:ghost_user) { { id: -1, login: 'Ghost' } }

  subject(:user_formatter) { described_class.new(client, gitea_user, project, source_user_mapper) }

  describe '#gitlab_id' do
    context 'when the user exists on Gitea' do
      before do
        allow(client).to receive(:user).and_return(gitea_user)
      end

      context 'when a placeholder user does not exist for the id from Gitea' do
        it 'creates a new source user' do
          expect { user_formatter.gitlab_id }.to change { Import::SourceUser.count }.from(0).to(1)
        end

        it 'returns a new placeholder user id' do
          expect(user_formatter.gitlab_id).not_to be_nil
          expect(User.find(user_formatter.gitlab_id)).to be_placeholder
        end
      end

      context 'when a placeholder user exists for the id from Gitea' do
        let!(:source_user) do
          create(
            :import_source_user,
            source_user_identifier: gitea_user[:id],
            source_hostname: 'https://gitea.com',
            import_type: project.import_type,
            namespace: project.root_ancestor
          )
        end

        it 'returns the existing placeholder user id' do
          expect(user_formatter.gitlab_id).to eq(source_user.placeholder_user_id)
        end
      end

      context 'when a placeholder has already been reassigned to a real user' do
        let!(:source_user) do
          create(
            :import_source_user,
            :completed,
            source_user_identifier: gitea_user[:id],
            source_hostname: 'https://gitea.com',
            import_type: project.import_type,
            namespace: project.root_ancestor
          )
        end

        it 'returns the reassigned user id' do
          expect(user_formatter.gitlab_id).to eq(source_user.reassign_to_user_id)
        end
      end

      context 'when importing into a personal namespace' do
        let_it_be(:user_namespace) { create(:namespace) }

        before_all do
          project.update!(namespace: user_namespace)
        end

        it 'returns the personal namespace owner id without creating a source user' do
          expect { user_formatter.gitlab_id }.not_to change { Import::SourceUser.count }
          expect(user_formatter.gitlab_id).to eq(user_namespace.owner_id)
        end

        context 'when user_mapping_to_personal_namespace_owner is disabled' do
          before_all do
            project.build_or_assign_import_data(
              data: { user_mapping_to_personal_namespace_owner_enabled: false }
            ).save!
          end

          it 'returns the import user id' do
            expect(user_formatter.gitlab_id).to eq(user_namespace.namespace_import_user.user_id)
          end
        end
      end

      context 'when user contribution mapping is disabled' do
        before do
          allow(client).to receive(:user).and_return(gitea_user)
          project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        end

        it 'returns GitLab user id when user confirmed primary email matches Gitea email' do
          gl_user = create(:user, email: gitea_user[:email])

          expect(user_formatter.gitlab_id).to eq gl_user.id
        end

        it 'returns GitLab user id when user unconfirmed primary email matches Gitea email' do
          gl_user = create(:user, :unconfirmed, email: gitea_user[:email])

          expect(user_formatter.gitlab_id).to eq gl_user.id
        end

        it 'returns GitLab user id when user confirmed secondary email matches Gitea email' do
          gl_user = create(:user, email: 'johndoe@example.com')
          create(:email, :confirmed, user: gl_user, email: gitea_user[:email])

          expect(user_formatter.gitlab_id).to eq gl_user.id
        end

        it 'returns nil when user unconfirmed secondary email matches Gitea email' do
          gl_user = create(:user, email: 'johndoe@example.com')
          create(:email, user: gl_user, email: gitea_user[:email])

          expect(user_formatter.gitlab_id).to be_nil
        end
      end
    end

    context 'when the user has been deleted on Gitea', :clean_gitlab_redis_shared_state do
      subject(:user_formatter) { described_class.new(client, ghost_user, project, source_user_mapper) }

      it 'returns gitlab ghost user id' do
        expect(user_formatter.gitlab_id).to eq gitlab_ghost_user.id
      end

      it 'does not create a placeholder user for ghost users' do
        expect { user_formatter.gitlab_id }.not_to change { Import::SourceUser.count }.from(0)
        expect { user_formatter.gitlab_id }.not_to change { User.where(user_type: :placeholder).count }.from(0)
      end

      context 'when importing into a personal namespace' do
        let_it_be(:user_namespace) { create(:namespace) }

        before_all do
          project.update!(namespace: user_namespace)
        end

        it 'returns the gitlab ghost user id without creating a source user' do
          expect { user_formatter.gitlab_id }.not_to change { Import::SourceUser.count }
          expect(user_formatter.gitlab_id).to eq(gitlab_ghost_user.id)
        end

        context 'when user_mapping_to_personal_namespace_owner is disabled' do
          before_all do
            project.build_or_assign_import_data(
              data: { user_mapping_to_personal_namespace_owner_enabled: false }
            ).save!
          end

          it 'returns the gitlab ghost user id', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/565885' do
            expect(user_formatter.gitlab_id).to eq(gitlab_ghost_user.id)
          end
        end
      end

      context 'and improved user mapping is disabled' do
        before do
          allow(client).to receive(:user).and_return(ghost_user)
          project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
        end

        it 'returns nil' do
          expect(user_formatter.gitlab_id).to be_nil
        end
      end
    end
  end

  describe '#source_user', :aggregate_failures do
    context 'when the user exists on Gitea' do
      before do
        allow(client).to receive(:user).and_return(gitea_user)
      end

      context 'and a source user does not exist' do
        it 'creates and returns new source user' do
          expect { user_formatter.source_user }.to change { Import::SourceUser.count }.from(0).to(1)
          expect(user_formatter.source_user.class).to eq(Import::SourceUser)
        end

        it "creates a placeholder with the user's full name and username" do
          source_user = user_formatter.source_user

          expect(source_user).to have_attributes(
            source_user_identifier: gitea_user[:id].to_s,
            source_username: gitea_user[:login],
            source_name: gitea_user[:full_name]
          )
        end

        context 'when the gitea user has no full name' do
          let(:gitea_user) { { id: 123456, login: 'octocat', email: 'user@email.com', full_name: '' } }

          it 'falls back to the gitea username' do
            source_user = user_formatter.source_user

            expect(source_user).to have_attributes(
              source_user_identifier: gitea_user[:id].to_s,
              source_username: gitea_user[:login],
              source_name: gitea_user[:login]
            )
          end
        end
      end

      context 'and a source user already exists' do
        let!(:source_user) do
          create(
            :import_source_user,
            source_user_identifier: gitea_user[:id],
            source_hostname: 'https://gitea.com',
            import_type: project.import_type,
            namespace: project.root_ancestor
          )
        end

        it 'returns the existing source user' do
          expect(user_formatter.source_user.id).to eq(source_user.id)
        end
      end
    end

    context 'when the source user has been deleted on gitea' do
      subject(:user_formatter) { described_class.new(client, ghost_user, project, source_user_mapper) }

      it 'returns nil' do
        expect(user_formatter.source_user).to be_nil
      end
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }

      before_all do
        project.update!(namespace: user_namespace)
      end

      it 'returns nil' do
        expect(user_formatter.source_user).to be_nil
      end

      context 'when user_mapping_to_personal_namespace_owner is disabled' do
        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'returns a source user' do
          allow(client).to receive(:user).and_return(gitea_user)

          expect(user_formatter.source_user).to be_an_instance_of(Import::SourceUser)
        end
      end
    end

    context 'when user contribution mapping is disabled' do
      before do
        allow(client).to receive(:user).and_return(gitea_user)
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'returns nil' do
        expect(user_formatter.source_user).to be_nil
      end
    end
  end
end
