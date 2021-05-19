# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::GitAccessDesign do
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
      it do
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
