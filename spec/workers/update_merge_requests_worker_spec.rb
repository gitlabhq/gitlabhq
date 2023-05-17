# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UpdateMergeRequestsWorker, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user)    { create(:user) }
  let_it_be(:oldrev)  { "123456" }
  let_it_be(:newrev)  { "789012" }
  let_it_be(:ref)     { "refs/heads/test" }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject { worker.perform(project.id, user.id, oldrev, newrev, ref) }

    it 'executes MergeRequests::RefreshService with expected values' do
      expect_next_instance_of(MergeRequests::RefreshService,
        project: project,
        current_user: user,
        params: { push_options: nil }) do |service|
        expect(service)
          .to receive(:execute)
          .with(oldrev, newrev, ref)
      end

      subject
    end

    context 'when push options are passed as Hash' do
      let(:extra_params) { { 'push_options' => { 'ci' => { 'skip' => true } } } }

      subject { worker.perform(project.id, user.id, oldrev, newrev, ref, extra_params) }

      it 'executes MergeRequests::RefreshService with expected values' do
        expect_next_instance_of(MergeRequests::RefreshService,
          project: project,
          current_user: user,
          params: { push_options: { ci: { skip: true } } }) do |service|
          expect(service)
            .to receive(:execute)
            .with(oldrev, newrev, ref)
        end

        subject
      end
    end
  end
end
