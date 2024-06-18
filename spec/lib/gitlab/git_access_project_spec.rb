# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitAccessProject do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:container) { project }
  let(:actor) { user }
  let(:project_path) { project.path }
  let(:namespace_path) { project&.namespace&.path }
  let(:repository_path) { "#{namespace_path}/#{project_path}.git" }
  let(:protocol) { 'ssh' }
  let(:authentication_abilities) { %i[read_project download_code push_code] }
  let(:changes) { Gitlab::GitAccess::ANY }
  let(:push_access_check) { access.check('git-receive-pack', changes) }
  let(:pull_access_check) { access.check('git-upload-pack', changes) }
  let(:access) do
    described_class.new(actor, container, protocol,
      authentication_abilities: authentication_abilities,
      repository_path: repository_path)
  end

  describe '#check_namespace!' do
    context 'when namespace is nil' do
      let(:namespace_path) { nil }

      it 'does not allow push and pull access' do
        aggregate_failures do
          expect { push_access_check }.to raise_namespace_not_found
          expect { pull_access_check }.to raise_namespace_not_found
        end
      end
    end
  end

  describe '#check_project_accessibility!' do
    context 'when the project is nil' do
      let(:container) { nil }
      let(:project_path) { "new-project" }

      context 'when user is allowed to create project in namespace' do
        let(:namespace_path) { user.namespace.path }

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
    before do
      allow(access).to receive(:changes).and_return(changes)
    end

    shared_examples 'no project is created' do
      let(:raise_specific_error) { raise_not_found }
      let(:action) { push_access_check }

      it 'does not create a new project' do
        expect { action }
          .to raise_specific_error
          .and change { Project.count }.by(0)
      end
    end

    context 'when push' do
      let(:cmd) { 'git-receive-pack' }

      context 'when project does not exist' do
        let(:project_path) { "nonexistent" }
        let(:container) { nil }

        context 'when changes is _any' do
          let(:changes) { Gitlab::GitAccess::ANY }

          context 'when authentication abilities include push code' do
            let(:authentication_abilities) { [:push_code] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it 'creates a new project in the correct namespace' do
                expect { push_access_check }
                  .to change { Project.count }.by(1)
                  .and change { Project.where(namespace: user.namespace, name: project_path).count }.by(1)
              end
            end

            context 'when namespace is blank' do
              let(:repository_path) { 'project.git' }

              it_behaves_like 'no project is created' do
                let(:raise_specific_error) { raise_namespace_not_found }
              end
            end

            context 'when namespace does not exist' do
              let(:namespace_path) { 'unknown' }

              it_behaves_like 'no project is created'
            end

            context 'when user cannot create project in namespace' do
              let(:user2) { create(:user) }
              let(:namespace_path) { user2.namespace.path }

              it_behaves_like 'no project is created'
            end
          end

          context 'when authentication abilities do not include push code' do
            let(:authentication_abilities) { [] }

            context 'when user can create project in namespace' do
              let(:namespace_path) { user.namespace.path }

              it_behaves_like 'no project is created' do
                let(:raise_specific_error) { raise_forbidden }
              end
            end
          end
        end

        context 'when check contains actual changes' do
          let(:changes) do
            "#{Gitlab::Git::SHA1_BLANK_SHA} 570e7b2abdd848b95f2f578043fc23bd6f6fd24d refs/heads/new_branch"
          end

          it_behaves_like 'no project is created'
        end
      end

      context 'when project exists' do
        let(:changes) { Gitlab::GitAccess::ANY }
        let!(:container) { project }

        it_behaves_like 'no project is created'
      end

      context 'when deploy key is used' do
        let(:key) { create(:deploy_key, user: user) }
        let(:actor) { key }
        let(:project_path) { "nonexistent" }
        let(:container) { nil }
        let(:namespace_path) { user.namespace.path }
        let(:changes) { Gitlab::GitAccess::ANY }

        it_behaves_like 'no project is created'
      end
    end

    context 'when pull' do
      let(:cmd) { 'git-upload-pack' }
      let(:changes) { Gitlab::GitAccess::ANY }

      context 'when project does not exist' do
        let(:project_path) { "new-project" }
        let(:namespace_path) { user.namespace.path }
        let(:container) { nil }

        it_behaves_like 'no project is created' do
          let(:action)  { pull_access_check }
        end
      end
    end
  end

  def raise_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, Gitlab::GitAccess::ERROR_MESSAGES[:project_not_found])
  end

  def raise_forbidden
    raise_error(Gitlab::GitAccess::ForbiddenError)
  end

  def raise_namespace_not_found
    raise_error(Gitlab::GitAccess::NotFoundError, described_class::ERROR_MESSAGES[:namespace_not_found])
  end
end
