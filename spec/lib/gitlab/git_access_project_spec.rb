# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GitAccessProject do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }
  let(:actor) { user }
  let(:project_path) { project.path }
  let(:namespace_path) { project&.namespace&.path }
  let(:protocol) { 'ssh' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }

  describe '#check_project_accessibility!' do
    context 'when the project is nil' do
      let(:project) { nil }
      let(:project_path) { "new-project" }

      context 'when user is allowed to create project in namespace' do
        let(:namespace_path) { user.namespace.path }
        let(:access) do
          described_class.new(actor, nil,
            protocol, authentication_abilities: authentication_abilities,
            repository_path: project_path, namespace_path: namespace_path)
        end

        it 'blocks pull access with "not found"' do
          expect { pull_access_check }.to raise_not_found
        end

        it 'allows push access' do
          expect { push_access_check }.not_to raise_error
        end
      end

      context 'when user is not allowed to create project in namespace' do
        let(:user2) { create(:user) }
        let(:namespace_path) { user2.namespace.path }
        let(:access) do
          described_class.new(actor, nil,
            protocol, authentication_abilities: authentication_abilities,
            repository_path: project_path, namespace_path: namespace_path)
        end

        it 'blocks push and pull with "not found"' do
          aggregate_failures do
            expect { pull_access_check }.to raise_not_found
            expect { push_access_check }.to raise_not_found
          end
        end
      end
    end
  end

  describe '#ensure_project_on_push!' do
    let(:access) do
      described_class.new(actor, project,
        protocol, authentication_abilities: authentication_abilities,
        repository_path: project_path, namespace_path: namespace_path)
    end

    before do
      allow(access).to receive(:changes).and_return(changes)
    end

    context 'when push' do
      let(:cmd) { 'git-receive-pack' }

      context 'when project does not exist' do
        let(:project_path) { "nonexistent" }
        let(:project) { nil }

        context 'when changes is _any' do
          let(:changes) { Gitlab::GitAccess::ANY }

          context 'when authentication abilities include push code' do
            let(:authentication_abilities) { [:push_code] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it 'creates a new project' do
                expect { access.send(:ensure_project_on_push!, cmd) }
                  .to change { Project.count }.by(1)
                  .and change { Project.where(namespace: user.namespace, name: project_path).count }.by(1)
              end
            end

            context 'when user cannot create project in namespace' do
              let(:user2) { create(:user) }
              let(:namespace_path) { user2.namespace.path }

              it 'does not create a new project' do
                expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
              end
            end
          end

          context 'when authentication abilities do not include push code' do
            let(:authentication_abilities) { [] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it 'does not create a new project' do
                expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
              end
            end
          end
        end

        context 'when check contains actual changes' do
          let(:changes) { "#{Gitlab::Git::BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch" }

          it 'does not create a new project' do
            expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
          end
        end
      end

      context 'when project exists' do
        let(:changes) { Gitlab::GitAccess::ANY }
        let!(:project) { create(:project) }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
        end
      end

      context 'when deploy key is used' do
        let(:key) { create(:deploy_key, user: user) }
        let(:actor) { key }
        let(:project_path) { "nonexistent" }
        let(:project) { nil }
        let(:namespace_path) { user.namespace.path }
        let(:changes) { Gitlab::GitAccess::ANY }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
        end
      end
    end

    context 'when pull' do
      let(:cmd) { 'git-upload-pack' }
      let(:changes) { Gitlab::GitAccess::ANY }

      context 'when project does not exist' do
        let(:project_path) { "new-project" }
        let(:namespace_path) { user.namespace.path }
        let(:project) { nil }

        it 'does not create a new project' do
          expect { access.send(:ensure_project_on_push!, cmd) }.not_to change { Project.count }
        end
      end
    end
  end

  def raise_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:project_not_found])
  end
end
