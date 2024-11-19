# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ProjectBuilder, feature_category: :webhooks do
  let_it_be(:user) { create(:user, name: 'John', email: 'john@example.com') }
  let_it_be(:user2) { create(:user, name: 'Peter') }
  let_it_be(:user3_non_owner) { create(:user, name: 'Not_Owner') }
  let(:include_deprecated_owner) { false }

  describe '#build' do
    let(:data) { described_class.new(project).build(event, include_deprecated_owner: include_deprecated_owner) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :created_at,
        :event_name,
        :name,
        :owners,
        :path,
        :path_with_namespace,
        :project_id,
        :project_namespace_id,
        :project_visibility,
        :updated_at
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:created_at]).to eq(project.created_at.xmlschema)
          expect(data[:updated_at]).to eq(project.updated_at.xmlschema)
          expect(data[:name]).to eq(project.name)
          expect(data[:path]).to eq(project.path)
          expect(data[:path_with_namespace]).to eq(project.full_path)
          expect(data[:project_id]).to eq(project.id)
          expect(data[:project_namespace_id]).to eq(project.namespace_id)
          expect(data[:owners]).to match_array(owners_data)
          expect(data[:project_visibility]).to eq('internal')
        end

        it 'does not include deprecated owner attributes' do
          expect(data).not_to include(:owner_name)
          expect(data).not_to include(:owner_email)
        end

        context 'when include_deprecated_owner is true' do
          let(:include_deprecated_owner) { true }

          it 'includes deprecated owner attributes' do
            expect(data[:owner_name]).to eq(owner_name)
            expect(data[:owner_email]).to eq(owner_email)
          end
        end
      end

      shared_examples_for 'does not include `old_path_with_namespace` attribute' do
        it 'does not include `old_path_with_namespace` attribute' do
          expect(data).not_to include(:old_path_with_namespace)
        end
      end

      shared_examples_for 'includes `old_path_with_namespace` attribute' do
        it 'includes `old_path_with_namespace` attribute' do
          allow(project).to receive(:old_path_with_namespace).and_return('old-path-with-namespace')
          expect(data[:old_path_with_namespace]).to eq('old-path-with-namespace')
        end
      end

      context 'the project is created in a personal namespace' do
        let(:owner_name) { user.name }
        let(:owner_email) { _('[REDACTED]') }
        let(:owners_data) { [{ name: 'John', email: _('[REDACTED]') }, { name: 'Peter', email: _('[REDACTED]') }] }
        let_it_be(:namespace) { create(:namespace, owner: user) }
        let_it_be(:project) { create(:project, :internal, name: 'personal project', namespace: namespace) }

        before_all do
          project.add_owner(user2)
          project.add_maintainer(user3_non_owner)
        end

        context 'on create' do
          let(:event) { :create }

          it { expect(event_name).to eq('project_create') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'does not include `old_path_with_namespace` attribute'
        end

        context 'on destroy' do
          let(:event) { :destroy }

          it { expect(event_name).to eq('project_destroy') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'does not include `old_path_with_namespace` attribute'
        end

        context 'on rename' do
          let(:event) { :rename }

          it { expect(event_name).to eq('project_rename') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'includes `old_path_with_namespace` attribute'
        end

        context 'on transfer' do
          let(:event) { :transfer }

          it { expect(event_name).to eq('project_transfer') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'includes `old_path_with_namespace` attribute'
        end
      end

      context 'the project is created in a group' do
        let(:owner_name) { group.name }
        let(:owner_email) { "" }
        let_it_be(:group) { create(:group) }
        let_it_be(:project) { create(:project, :internal, name: 'group project', namespace: group) }
        let(:owners_data) { [{ name: 'John', email: _('[REDACTED]') }, { email: "[REDACTED]", name: "Peter" }] }

        before_all do
          group.add_owner(user)
          group.add_owner(user2)
          group.add_maintainer(user3_non_owner)
        end

        # Repeat the tests in the previous context
        context 'on create' do
          let(:event) { :create }

          it { expect(event_name).to eq('project_create') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'does not include `old_path_with_namespace` attribute'

          context 'group has pending owner invitation' do
            let_it_be(:group) { create(:group) }
            let_it_be(:project) { create(:project, :internal, name: 'group project', namespace: group) }

            let(:owners_data) { [] }

            before do
              create(:group_member, :invited, group: group)
            end

            it { expect(event_name).to eq('project_create') }
          end
        end

        context 'on destroy' do
          let(:event) { :destroy }

          it { expect(event_name).to eq('project_destroy') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'does not include `old_path_with_namespace` attribute'
        end

        context 'on rename' do
          let(:event) { :rename }

          it { expect(event_name).to eq('project_rename') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'includes `old_path_with_namespace` attribute'
        end

        context 'on transfer' do
          let(:event) { :transfer }

          it { expect(event_name).to eq('project_transfer') }

          it_behaves_like 'includes the required attributes'
          it_behaves_like 'includes `old_path_with_namespace` attribute'
        end
      end
    end
  end
end
