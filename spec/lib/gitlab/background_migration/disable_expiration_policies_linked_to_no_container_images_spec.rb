# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::DisableExpirationPoliciesLinkedToNoContainerImages do
  let_it_be(:projects) { table(:projects) }
  let_it_be(:container_expiration_policies) { table(:container_expiration_policies) }
  let_it_be(:container_repositories) { table(:container_repositories) }
  let_it_be(:namespaces) { table(:namespaces) }

  let!(:namespace) { namespaces.create!(name: 'test', path: 'test') }

  let!(:policy1) { create_expiration_policy(project_id: 1, enabled: true) }
  let!(:policy2) { create_expiration_policy(project_id: 2, enabled: false) }
  let!(:policy3) { create_expiration_policy(project_id: 3, enabled: false) }
  let!(:policy4) { create_expiration_policy(project_id: 4, enabled: true, with_images: true) }
  let!(:policy5) { create_expiration_policy(project_id: 5, enabled: false, with_images: true) }
  let!(:policy6) { create_expiration_policy(project_id: 6, enabled: false) }
  let!(:policy7) { create_expiration_policy(project_id: 7, enabled: true) }
  let!(:policy8) { create_expiration_policy(project_id: 8, enabled: true, with_images: true) }
  let!(:policy9) { create_expiration_policy(project_id: 9, enabled: true) }

  describe '#perform' do
    subject { described_class.new.perform(from_id, to_id) }

    shared_examples 'disabling policies with no images' do
      it 'disables the proper policies' do
        subject

        rows = container_expiration_policies.order(:project_id).to_h do |row|
          [row.project_id, row.enabled]
        end
        expect(rows).to eq(expected_rows)
      end
    end

    context 'the whole range' do
      let(:from_id) { 1 }
      let(:to_id) { 9 }

      it_behaves_like 'disabling policies with no images' do
        let(:expected_rows) do
          {
            1 => false,
            2 => false,
            3 => false,
            4 => true,
            5 => false,
            6 => false,
            7 => false,
            8 => true,
            9 => false
          }
        end
      end
    end

    context 'a range with no policies to disable' do
      let(:from_id) { 2 }
      let(:to_id) { 6 }

      it_behaves_like 'disabling policies with no images' do
        let(:expected_rows) do
          {
            1 => true,
            2 => false,
            3 => false,
            4 => true,
            5 => false,
            6 => false,
            7 => true,
            8 => true,
            9 => true
          }
        end
      end
    end

    context 'a range with only images' do
      let(:from_id) { 4 }
      let(:to_id) { 5 }

      it_behaves_like 'disabling policies with no images' do
        let(:expected_rows) do
          {
            1 => true,
            2 => false,
            3 => false,
            4 => true,
            5 => false,
            6 => false,
            7 => true,
            8 => true,
            9 => true
          }
        end
      end
    end

    context 'a range with a single element' do
      let(:from_id) { 9 }
      let(:to_id) { 9 }

      it_behaves_like 'disabling policies with no images' do
        let(:expected_rows) do
          {
            1 => true,
            2 => false,
            3 => false,
            4 => true,
            5 => false,
            6 => false,
            7 => true,
            8 => true,
            9 => false
          }
        end
      end
    end
  end

  def create_expiration_policy(project_id:, enabled:, with_images: false)
    projects.create!(id: project_id, namespace_id: namespace.id, name: "gitlab-#{project_id}")

    if with_images
      container_repositories.create!(project_id: project_id, name: "image-#{project_id}")
    end

    container_expiration_policies.create!(
      enabled: enabled,
      project_id: project_id
    )
  end

  def enabled_policies
    container_expiration_policies.where(enabled: true)
  end

  def disabled_policies
    container_expiration_policies.where(enabled: false)
  end
end
