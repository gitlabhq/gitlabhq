# frozen_string_literal: true

RSpec.shared_examples 'a deployable job policy in EE' do |factory_type|
  using RSpec::Parameterized::TableSyntax

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  let(:user) { create(:user) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:environment) { create(:environment, project: project, name: 'production') }

  let(:job) do
    create(factory_type, pipeline: pipeline, project: project, environment: 'production', ref: 'development')
  end

  describe '#update_build?' do
    subject { user.can?(:update_build, job) }

    it_behaves_like 'protected environments access', direct_access: true
  end

  describe '#cancel_build?' do
    subject { user.can?(:cancel_build, job) }

    it_behaves_like 'protected environments access', direct_access: true
  end

  describe '#update_commit_status?' do
    subject { user.can?(:update_commit_status, job) }

    it_behaves_like 'protected environments access', direct_access: true
  end

  describe '#erase_build?' do
    subject { user.can?(:erase_build, job) }

    context 'when the job triggerer is a project maintainer' do
      let_it_be_with_refind(:user) { create(:user, maintainer_of: project) }

      before do
        stub_licensed_features(protected_environments: true)
      end

      it 'returns true for ci_build' do
        # Currently, we allow users to delete normal jobs only.
        if factory_type == :ci_build
          is_expected.to eq(true)
        else
          is_expected.to eq(false)
        end
      end

      context 'when environment is protected' do
        before do
          create(:protected_environment, name: environment.name, project: project)
        end

        it { is_expected.to eq(false) }
      end
    end
  end
end
