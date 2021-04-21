# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Pipeline::Chain::Validate::Repository do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build_stubbed(:ci_pipeline) }
  let!(:step) { described_class.new(pipeline, command) }

  before do
    step.perform!
  end

  context 'when ref and sha exists' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project, current_user: user, origin_ref: 'master', checkout_sha: project.commit.id)
    end

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not append pipeline errors' do
      expect(pipeline.errors).to be_empty
    end
  end

  context 'when ref does not exist' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project, current_user: user, origin_ref: 'something')
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'adds an error about missing ref' do
      expect(pipeline.errors.to_a)
        .to include 'Reference not found'
    end
  end

  context 'when origin ref is a merge request ref' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project, current_user: user, origin_ref: origin_ref, checkout_sha: checkout_sha)
    end

    let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }
    let(:origin_ref) { merge_request.ref_path }
    let(:checkout_sha) { project.repository.commit(merge_request.ref_path).id }

    it 'does not break the chain' do
      expect(step.break?).to be false
    end

    it 'does not append pipeline errors' do
      expect(pipeline.errors).to be_empty
    end
  end

  context 'when ref is ambiguous' do
    let(:project) do
      create(:project, :repository).tap do |proj|
        proj.repository.add_tag(user, 'master', 'master')
      end
    end

    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project, current_user: user, origin_ref: 'master')
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'adds an error about missing ref' do
      expect(pipeline.errors.to_a)
        .to include 'Ref is ambiguous'
    end
  end

  context 'when does not have existing SHA set' do
    let(:command) do
      Gitlab::Ci::Pipeline::Chain::Command.new(
        project: project, current_user: user, origin_ref: 'master', checkout_sha: 'something')
    end

    it 'breaks the chain' do
      expect(step.break?).to be true
    end

    it 'adds an error about missing SHA' do
      expect(pipeline.errors.to_a)
        .to include 'Commit not found'
    end
  end
end
