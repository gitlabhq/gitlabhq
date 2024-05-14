# frozen_string_literal: true

RSpec.shared_examples 'a deployable job policy' do |factory_type|
  let_it_be_with_refind(:project) { create(:project, :private) }
  let_it_be_with_refind(:user) { create(:user) }

  let(:job) { create(factory_type, project: project, user: user, environment: 'production', ref: 'development') }
  let(:policy) { described_class.new(user, job) }

  context 'when the job triggerer is a project maintainer' do
    before_all do
      project.add_maintainer(user)
    end

    it { expect(policy).to be_allowed :update_build }

    context 'when job is oudated deployment job' do
      before do
        allow(job).to receive(:has_outdated_deployment?).and_return(true)
      end

      it { expect(policy).not_to be_allowed :update_build }
      it { expect(policy).not_to be_allowed :cancel_build }
    end
  end
end
