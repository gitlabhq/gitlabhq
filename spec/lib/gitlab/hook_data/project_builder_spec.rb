# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::HookData::ProjectBuilder do
  let_it_be(:user) { create(:user, name: 'John', email: 'john@example.com') }
  let_it_be(:namespace) { create(:namespace, owner: user) }
  let_it_be(:project) { create(:project, :internal, name: 'my_project', namespace: namespace) }

  describe '#build' do
    let(:data) { described_class.new(project).build(event) }
    let(:event_name) { data[:event_name] }
    let(:attributes) do
      [
        :event_name, :created_at, :updated_at, :name, :path, :path_with_namespace, :project_id,
        :owner_name, :owner_email, :project_visibility
      ]
    end

    context 'data' do
      shared_examples_for 'includes the required attributes' do
        it 'includes the required attributes' do
          expect(data).to include(*attributes)

          expect(data[:created_at]).to eq(project.created_at.xmlschema)
          expect(data[:updated_at]).to eq(project.updated_at.xmlschema)
          expect(data[:name]).to eq('my_project')
          expect(data[:path]).to eq(project.path)
          expect(data[:path_with_namespace]).to eq(project.full_path)
          expect(data[:project_id]).to eq(project.id)
          expect(data[:owner_name]).to eq('John')
          expect(data[:owner_email]).to eq('john@example.com')
          expect(data[:project_visibility]).to eq('internal')
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
  end
end
