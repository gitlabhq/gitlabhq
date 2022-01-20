# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::UpdateService do
  let(:protected_branch) { create(:protected_branch) }
  let(:project) { protected_branch.project }
  let(:user) { project.first_owner }
  let(:params) { { name: new_name } }

  describe '#execute' do
    let(:new_name) { 'new protected branch name' }
    let(:result) { service.execute(protected_branch) }

    subject(:service) { described_class.new(project, user, params) }

    it 'updates a protected branch' do
      expect(result.reload.name).to eq(params[:name])
    end

    context 'when name has escaped HTML' do
      let(:new_name) { 'feature-&gt;test' }

      it 'updates protected branch name with unescaped HTML' do
        expect(result.reload.name).to eq('feature->test')
      end

      context 'and name contains HTML tags' do
        let(:new_name) { '&lt;b&gt;master&lt;/b&gt;' }

        it 'updates protected branch name with sanitized name' do
          expect(result.reload.name).to eq('master')
        end

        context 'and contains unsafe HTML' do
          let(:new_name) { '&lt;script&gt;alert(&#39;foo&#39;);&lt;/script&gt;' }

          it 'does not update the protected branch' do
            expect(result.reload.name).to eq(protected_branch.name)
          end
        end
      end
    end

    context 'when name contains unescaped HTML tags' do
      let(:new_name) { '<b>master</b>' }

      it 'updates protected branch name with sanitized name' do
        expect(result.reload.name).to eq('master')
      end
    end

    context 'without admin_project permissions' do
      let(:user) { create(:user) }

      it "raises error" do
        expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end

    context 'when a policy restricts rule creation' do
      before do
        policy = instance_double(ProtectedBranchPolicy, allowed?: false)
        expect(ProtectedBranchPolicy).to receive(:new).and_return(policy)
      end

      it "prevents creation of the protected branch rule" do
        expect { service.execute(protected_branch) }.to raise_error(Gitlab::Access::AccessDeniedError)
      end
    end
  end
end
