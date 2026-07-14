# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/authz_cop_bypass'

RSpec.describe Tooling::Danger::AuthzCopBypass, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:changed_files) { [file_path] }
  let(:changed_lines) { [] }
  let(:file_path) { 'app/services/widgets/create_service.rb' }

  subject(:authz_cop_bypass) { fake_danger.new(helper: fake_helper) }

  before do
    allow(fake_helper).to receive_messages(all_changed_files: changed_files, changed_lines: [])
    allow(fake_helper).to receive(:changed_lines).with(file_path).and_return(changed_lines)
    allow(fake_helper).to receive(:markdown_list) { |items| items.join("\n") }
  end

  describe '#add_comment_for_authz_cop_bypass' do
    shared_examples 'no comment' do
      it 'does not warn or post markdown', :aggregate_failures do
        expect(authz_cop_bypass).not_to receive(:markdown)
        expect(authz_cop_bypass).not_to receive(:warn)

        authz_cop_bypass.add_comment_for_authz_cop_bypass
      end
    end

    shared_examples 'a comment' do
      it 'posts markdown and warns once', :aggregate_failures do
        expect(authz_cop_bypass).to receive(:markdown).once
        expect(authz_cop_bypass).to receive(:warn).with(described_class::WARNING).once

        authz_cop_bypass.add_comment_for_authz_cop_bypass
      end
    end

    context 'when an added line disables an authz cop' do
      let(:changed_lines) do
        ['+    user.can?(:admin_issue, project) # rubocop:disable Gitlab/Authz/PermissionCheck -- no granular permission yet']
      end

      it_behaves_like 'a comment'
    end

    context 'when an added line adds a rubocop:todo for an authz cop' do
      let(:changed_lines) { ['+    Ability.allowed?(user, :manage_foo) # rubocop:todo Gitlab/Authz/PermissionCheck'] }

      it_behaves_like 'a comment'
    end

    context 'when the authz cop is one of several disabled cops on the line' do
      let(:changed_lines) { ['+    foo # rubocop:disable Style/Documentation, Gitlab/Authz/RoleCheckInRule'] }

      it_behaves_like 'a comment'
    end

    context 'when an added line disables a non-authz cop' do
      let(:changed_lines) { ['+    foo = bar # rubocop:disable Style/Documentation'] }

      it_behaves_like 'no comment'
    end

    context 'when the line uses a permission check without disabling a cop' do
      let(:changed_lines) { ['+    return unless can?(current_user, :read_widget, widget)'] }

      it_behaves_like 'no comment'
    end

    context 'when the authz cop disable only appears on a removed line' do
      let(:changed_lines) { ['-    user.can?(:admin_issue, project) # rubocop:disable Gitlab/Authz/PermissionCheck -- reason'] }

      it_behaves_like 'no comment'
    end

    context 'when the changed file is not a ruby file' do
      let(:file_path) { 'config/rubocop.yml' }
      let(:changed_lines) { ['+    # rubocop:disable Gitlab/Authz/PermissionCheck'] }

      it_behaves_like 'no comment'
    end

    context 'when an exclusion is added to an authz rubocop_todo file' do
      let(:file_path) { '.rubocop_todo/gitlab/authz/permission_check.yml' }
      let(:changed_lines) { ["+    - 'app/services/widgets/create_service.rb'"] }

      it_behaves_like 'a comment'
    end

    context 'when an exclusion is added to a non-authz rubocop_todo file' do
      let(:file_path) { '.rubocop_todo/style/documentation.yml' }
      let(:changed_lines) { ["+    - 'app/services/widgets/create_service.rb'"] }

      it_behaves_like 'no comment'
    end

    context 'when an exclusion is only removed from an authz rubocop_todo file' do
      let(:file_path) { '.rubocop_todo/gitlab/authz/permission_check.yml' }
      let(:changed_lines) { ["-    - 'app/services/widgets/create_service.rb'"] }

      it_behaves_like 'no comment'
    end

    context 'when an authz rubocop_todo file changes without adding an exclusion' do
      let(:file_path) { '.rubocop_todo/gitlab/authz/permission_check.yml' }
      let(:changed_lines) { ['+  Details: grace period'] }

      it_behaves_like 'no comment'
    end
  end
end
