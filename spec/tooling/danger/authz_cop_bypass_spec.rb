# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/authz_cop_bypass'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::AuthzCopBypass, feature_category: :tooling do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:changed_files) { [file_path] }
  let(:changed_lines) { [] }
  let(:file_path) { 'app/services/widgets/create_service.rb' }
  let(:draft_mr?) { false }
  let(:ci?) { false }
  let(:file_lines) { [] }
  let(:fake_project_helper) { instance_double(Tooling::Danger::ProjectHelper, file_lines: file_lines) }

  subject(:authz_cop_bypass) { fake_danger.new(helper: fake_helper) }

  before do
    allow(fake_helper).to receive_messages(
      all_changed_files: changed_files, changed_lines: [], draft_mr?: draft_mr?, ci?: ci?
    )
    allow(fake_helper).to receive(:changed_lines).with(file_path).and_return(changed_lines)
    allow(fake_helper).to receive(:markdown_list) { |items| items.join("\n") }
    allow(authz_cop_bypass).to receive(:project_helper).and_return(fake_project_helper)
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

      context 'when the merge request is a draft' do
        let(:draft_mr?) { true }

        it_behaves_like 'no comment'
      end

      context 'when the line is found in the file' do
        let(:file_lines) { ['class Foo', changed_lines.first.delete_prefix('+'), 'end'] }

        it 'comments on that line', :aggregate_failures do
          expect(authz_cop_bypass).to receive(:markdown)
            .with(a_string_including(described_class::LINE_COMMENT), file: file_path, line: 2)
          expect(authz_cop_bypass).to receive(:markdown).with(a_string_including('## Authorization review'))
          allow(authz_cop_bypass).to receive(:warn)

          authz_cop_bypass.add_comment_for_authz_cop_bypass
        end
      end
    end

    context 'when the file quotes the directive as test data' do
      let(:changed_lines) { ['+    # rubocop:disable Gitlab/Authz/PermissionCheck -- reason'] }

      %w[
        rubocop/cop/gitlab/authz/permission_check.rb
        spec/rubocop/cop/gitlab/authz/permission_check_spec.rb
        spec/tooling/danger/authz_cop_bypass_spec.rb
      ].each do |path|
        context "with #{path}" do
          let(:file_path) { path }

          it_behaves_like 'no comment'
        end
      end
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

  describe 'accountable reviewer' do
    let(:ci?) { true }
    let(:changed_lines) { ['+    foo # rubocop:disable Gitlab/Authz/PermissionCheck -- reason'] }
    let(:fake_api) { double('GitLab API') } # rubocop:disable RSpec/VerifiedDoubles -- type is not relevant
    let(:approvers) do
      [
        { 'id' => 3, 'username' => 'carol' },
        { 'id' => 1, 'username' => 'alice' },
        { 'id' => 2, 'username' => 'bob' }
      ]
    end

    let(:available) { %w[alice bob carol] }
    let(:reviewers) { [{ 'id' => 9, 'username' => 'someone' }] }

    before do
      allow(authz_cop_bypass).to receive_message_chain(:gitlab, :api).and_return(fake_api)
      allow(authz_cop_bypass).to receive_message_chain(:gitlab, :mr_json).and_return({ 'project_id' => 1, 'iid' => 2 })
      allow(fake_api).to receive(:group_members).with(described_class::APPROVERS_GROUP)
        .and_return(double(auto_paginate: approvers)) # rubocop:disable RSpec/VerifiedDoubles -- type is not relevant
      allow(fake_api).to receive(:update_merge_request)
      allow(fake_helper).to receive_messages(
        mr_reviewers: reviewers, mr_author: 'author', mr_source_branch: 'some-branch'
      )
      allow(Gitlab::Dangerfiles::Teammate).to receive(:find_member) do |username|
        instance_double(Gitlab::Dangerfiles::Teammate, available: available.include?(username))
      end
      allow(authz_cop_bypass).to receive(:warn)
    end

    def picked_username
      username = nil
      allow(authz_cop_bypass).to receive(:markdown) { |text| username = text[/@(\w+) can you please review/, 1] }

      authz_cop_bypass.add_comment_for_authz_cop_bypass

      username
    end

    it 'adds one available approver as a reviewer and names them', :aggregate_failures do
      username = picked_username
      picked = approvers.find { |approver| approver['username'] == username }

      expect(picked).not_to be_nil
      expect(fake_api).to have_received(:update_merge_request).with(1, 2, reviewer_ids: [9, picked['id']])
    end

    it 'picks from a shuffle seeded by the source branch' do
      shuffled = approvers.sort_by { |approver| approver['username'] }.shuffle(random: Random.new(Digest::SHA256.hexdigest('some-branch').to_i(16)))

      expect(picked_username).to eq(shuffled.first['username'])
    end

    context 'when an approver is already a reviewer' do
      let(:reviewers) { [{ 'id' => 2, 'username' => 'bob' }] }

      it 'names that approver without changing reviewers', :aggregate_failures do
        expect(picked_username).to eq('bob')
        expect(fake_api).not_to have_received(:update_merge_request)
      end
    end

    context 'when the author is the only available approver' do
      let(:approvers) { super() + [{ 'id' => 4, 'username' => 'author' }] }
      let(:available) { %w[author] }

      it 'does not pick the author' do
        expect(picked_username).to be_nil
      end
    end

    context 'when the approvers are not in the roulette data' do
      before do
        allow(Gitlab::Dangerfiles::Teammate).to receive(:find_member).and_return(nil)
      end

      it 'does not pick anyone' do
        expect(picked_username).to be_nil
      end
    end

    context 'when no approver is available' do
      let(:available) { [] }

      it 'does not add a reviewer and says nobody is available', :aggregate_failures do
        expect(authz_cop_bypass).to receive(:markdown)
          .with(a_string_including(described_class::NO_ACCOUNTABLE_REVIEWER))

        authz_cop_bypass.add_comment_for_authz_cop_bypass

        expect(fake_api).not_to have_received(:update_merge_request)
      end
    end

    context 'when fetching the approvers fails' do
      before do
        allow(fake_api).to receive(:group_members).and_raise(StandardError, 'not found')
      end

      it 'warns and says nobody is available', :aggregate_failures do
        expect(authz_cop_bypass).to receive(:markdown)
          .with(a_string_including(described_class::NO_ACCOUNTABLE_REVIEWER))

        authz_cop_bypass.add_comment_for_authz_cop_bypass

        expect(authz_cop_bypass).to have_received(:warn).with(a_string_including('not found'))
      end
    end

    context 'when loading the roulette data fails' do
      before do
        allow(Gitlab::Dangerfiles::Teammate).to receive(:find_member).and_raise(Net::OpenTimeout, 'execution expired')
      end

      it 'warns and says nobody is available', :aggregate_failures do
        expect(authz_cop_bypass).to receive(:markdown)
          .with(a_string_including(described_class::NO_ACCOUNTABLE_REVIEWER))

        authz_cop_bypass.add_comment_for_authz_cop_bypass

        expect(authz_cop_bypass).to have_received(:warn).with(a_string_including('execution expired'))
      end
    end

    context 'when adding the reviewer fails' do
      before do
        allow(fake_api).to receive(:update_merge_request).and_raise(StandardError, 'forbidden')
      end

      it 'warns and still posts the comment', :aggregate_failures do
        expect(authz_cop_bypass).to receive(:markdown).once

        authz_cop_bypass.add_comment_for_authz_cop_bypass

        expect(authz_cop_bypass).to have_received(:warn).with(a_string_including('forbidden'))
      end
    end
  end
end
