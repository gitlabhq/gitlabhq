# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Cleanup::UpdatePolicyService, feature_category: :package_registry do
  using RSpec::Parameterized::TableSyntax

  let_it_be_with_reload(:project) { create(:project) }
  let_it_be(:current_user) { create(:user) }

  let(:params) { { keep_n_duplicated_package_files: 50 } }

  describe '#execute' do
    subject { described_class.new(project: project, current_user: current_user, params: params).execute }

    shared_examples 'creating the policy' do
      it 'creates a new one' do
        expect { subject }.to change { ::Packages::Cleanup::Policy.count }.from(0).to(1)

        expect(subject.payload[:packages_cleanup_policy]).to be_present
        expect(subject.success?).to be_truthy
        expect(project.packages_cleanup_policy).to be_persisted
        expect(project.packages_cleanup_policy.keep_n_duplicated_package_files).to eq('50')
      end

      context 'with invalid parameters' do
        let(:params) { { keep_n_duplicated_package_files: 100 } }

        it 'does not create one' do
          expect { subject }.not_to change { ::Packages::Cleanup::Policy.count }

          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Keep n duplicated package files is invalid')
        end
      end
    end

    shared_examples 'updating the policy' do
      it 'updates the existing one' do
        expect { subject }.not_to change { ::Packages::Cleanup::Policy.count }

        expect(subject.payload[:packages_cleanup_policy]).to be_present
        expect(subject.success?).to be_truthy
        expect(project.packages_cleanup_policy.keep_n_duplicated_package_files).to eq('50')
      end

      context 'with invalid parameters' do
        let(:params) { { keep_n_duplicated_package_files: 100 } }

        it 'does not update one' do
          expect { subject }.not_to change { policy.keep_n_duplicated_package_files }

          expect(subject.status).to eq(:error)
          expect(subject.message).to eq('Keep n duplicated package files is invalid')
        end
      end
    end

    shared_examples 'denying access' do
      it 'returns an error' do
        subject

        expect(subject.message).to eq('Access denied')
        expect(subject.status).to eq(:error)
      end
    end

    context 'with existing container expiration policy' do
      let_it_be(:policy) { create(:packages_cleanup_policy, project: project) }

      where(:user_role, :shared_examples_name) do
        :maintainer | 'updating the policy'
        :developer  | 'denying access'
        :reporter   | 'denying access'
        :guest      | 'denying access'
        :anonymous  | 'denying access'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end

    context 'without existing container expiration policy' do
      where(:user_role, :shared_examples_name) do
        :maintainer | 'creating the policy'
        :developer  | 'denying access'
        :reporter   | 'denying access'
        :guest      | 'denying access'
        :anonymous  | 'denying access'
      end

      with_them do
        before do
          project.send("add_#{user_role}", current_user) unless user_role == :anonymous
        end

        it_behaves_like params[:shared_examples_name]
      end
    end
  end
end
