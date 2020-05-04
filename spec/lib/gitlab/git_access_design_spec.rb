# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GitAccessDesign do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let(:protocol) { 'web' }
  let(:actor) { user }

  subject(:access) do
    described_class.new(actor, project, protocol, authentication_abilities: [:read_project, :download_code, :push_code])
  end

  describe '#check' do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    before do
      enable_design_management
    end

    context 'when the user is allowed to manage designs' do
      # TODO This test is being temporarily skipped unless run in EE,
      # as we are in the process of moving Design Management to FOSS in 13.0
      # in steps. In the current step the policies have not yet been moved
      # which means that although the `GitAccessDesign` class has moved, the
      # user will always be denied access in FOSS.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283.
      it do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        is_expected.to be_a(::Gitlab::GitAccessResult::Success)
      end
    end

    context 'when the user is not allowed to manage designs' do
      let_it_be(:user) { create(:user) }

      it 'raises an error' do
        expect { subject }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
      end
    end

    context 'when the protocol is not web' do
      let(:protocol) { 'https' }

      it 'raises an error' do
        expect { subject }.to raise_error(::Gitlab::GitAccess::ForbiddenError)
      end
    end
  end
end
