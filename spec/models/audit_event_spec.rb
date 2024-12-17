# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvent do
  describe 'associations' do
    it { is_expected.to belong_to(:user).with_foreign_key(:author_id).inverse_of(:audit_events) }
  end

  describe 'validations' do
    include_examples 'validates IP address' do
      let(:attribute) { :ip_address }
      let(:object) { create(:audit_event) }
    end
  end

  # Do not update this spec, We are migrating audit events to new tables and want to ensure no columns are added or removed
  # issue_url: https://gitlab.com/gitlab-org/gitlab/-/issues/454174
  describe '.columns' do
    it 'does not change' do
      expect(described_class.columns.map(&:name).map(&:to_sym)).to match_array(
        [:id, :created_at, :author_id, :target_id, :details, :ip_address,
          :author_name, :entity_path, :target_details, :target_type,
          :entity_id, :entity_type])
    end
  end

  describe 'callbacks' do
    describe '#parallel_persist' do
      shared_examples 'a parallel persisted field' do
        using RSpec::Parameterized::TableSyntax

        where(:column, :details, :expected_value) do
          :value | nil | :value
          nil | :value | :value
          :value | :another_value | :value
          nil | nil | nil
        end

        with_them do
          let(:values) { { value: value, another_value: "#{value}88" } }

          let(:audit_event) do
            build(:audit_event, name => values[column], details: { name => values[details] })
          end

          it 'sets both values to be the same', :aggregate_failures do
            audit_event.validate

            expect(audit_event[name]).to eq(values[expected_value])
            expect(audit_event.details[name]).to eq(values[expected_value])
          end
        end
      end

      context 'wih author_name' do
        let(:name) { :author_name }
        let(:value) { 'Mary Poppins' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with entity_path' do
        let(:name) { :entity_path }
        let(:value) { 'gitlab-org' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_details' do
        let(:name) { :target_details }
        let(:value) { 'gitlab-org/gitlab' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_type' do
        let(:name) { :target_type }
        let(:value) { 'Project' }

        it_behaves_like 'a parallel persisted field'
      end

      context 'with target_id' do
        let(:name) { :target_id }
        let(:value) { 8 }

        it_behaves_like 'a parallel persisted field'
      end
    end
  end

  it 'sanitizes custom_message in the details hash' do
    audit_event = create(:project_audit_event, details: { target_id: 678, custom_message: '<strong>Arnold</strong>' })

    expect(audit_event.details).to include(
      target_id: 678,
      custom_message: 'Arnold'
    )
  end

  describe '#as_json' do
    context 'ip_address' do
      subject { build(:group_audit_event, ip_address: '192.168.1.1').as_json }

      it 'overrides the ip_address with its string value' do
        expect(subject['ip_address']).to eq('192.168.1.1')
      end
    end
  end

  describe '#author' do
    subject(:author) { audit_event.author }

    context "when the target type is not Ci::Runner" do
      let(:audit_event) { build(:project_audit_event, target_id: 678) }

      it 'returns a NullAuthor' do
        expect(::Gitlab::Audit::NullAuthor).to receive(:for).and_call_original

        is_expected.to be_a_kind_of(::Gitlab::Audit::NullAuthor)
      end
    end

    context 'when the target type is Ci::Runner and details contain runner_registration_token' do
      let_it_be(:project) { create(:project) }
      let(:audit_event) do
        build(:project_audit_event, target_project: project, target_type: ::Ci::Runner.name, target_id: 678,
          details: { runner_registration_token: 'abc123' })
      end

      it 'returns a CiRunnerTokenAuthor' do
        expect(::Gitlab::Audit::CiRunnerTokenAuthor).to receive(:new)
          .with(
            entity_type: project.class.name,
            entity_path: project.full_path,
            runner_registration_token: 'abc123')
          .and_call_original

        is_expected.to be_an_instance_of(::Gitlab::Audit::CiRunnerTokenAuthor)
      end

      it 'name consists of prefix and token' do
        expect(author.name).to eq('Registration token: abc123')
      end
    end
  end
end
