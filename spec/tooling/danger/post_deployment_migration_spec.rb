# frozen_string_literal: true

require 'danger'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/post_deployment_migration'

RSpec.describe Tooling::Danger::PostDeploymentMigration, feature_category: :delivery do
  subject(:pdm) { fake_danger.new(helper: fake_helper) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }

  include_context "with dangerfile"

  describe '#check_security_post_deployment_migrations' do
    let(:pdm_file)     { 'db/post_migrate/20260603000001_some_post_deploy.rb' }
    let(:ee_pdm_file)  { 'ee/db/post_migrate/20260603000002_some_ee_post_deploy.rb' }
    let(:regular_file) { 'db/migrate/20260603000003_some_regular.rb' }

    before do
      allow(pdm.helper).to receive_messages(
        all_changed_files: changed_files,
        security_mr?: security_mr,
        mr_labels: mr_labels,
        stable_branch?: false,
        ci?: true
      )
      # Silence the audit-discussion API call by default. Tests that assert on it
      # override this with an explicit `expect(...).to receive(:post_audit_discussion)`.
      allow(pdm).to receive(:post_audit_discussion)
    end

    context 'when the MR targets a stable branch' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [described_class::BYPASS_LABEL] }

      it 'does nothing even when the bypass label is present', :aggregate_failures do
        allow(pdm.helper).to receive(:stable_branch?).and_return(true)

        expect(pdm).not_to receive(:fail)
        expect(pdm).not_to receive(:warn)
        expect(pdm).not_to receive(:post_audit_discussion)
        expect(pdm).not_to receive(:remove_bypass_label)

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when not running in CI' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [] }

      it 'does not fail or warn', :aggregate_failures do
        allow(pdm.helper).to receive(:ci?).and_return(false)

        expect(pdm).not_to receive(:fail)
        expect(pdm).not_to receive(:warn)

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when the MR is not a security MR' do
      let(:security_mr)   { false }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [] }

      it 'does not fail or warn', :aggregate_failures do
        expect(pdm).not_to receive(:fail)
        expect(pdm).not_to receive(:warn)

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when the MR is a security MR but has no PDM files' do
      let(:security_mr)   { true }
      let(:changed_files) { [regular_file] }
      let(:mr_labels)     { [] }

      it 'does not fail or warn', :aggregate_failures do
        expect(pdm).not_to receive(:fail)
        expect(pdm).not_to receive(:warn)

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when a security MR includes a PDM file and the bypass label is absent' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [] }

      it 'fails with the default-block message and lists the migration files' do
        expect(pdm).to receive(:fail).with(
          a_string_including('post-deploy migration(s)').and(
            a_string_including(pdm_file)
          )
        )

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when a security MR includes an ee/db/post_migrate file and the bypass label is absent' do
      let(:security_mr)   { true }
      let(:changed_files) { [ee_pdm_file] }
      let(:mr_labels)     { [] }

      it 'still detects the EE path and fails' do
        expect(pdm).to receive(:fail).with(a_string_including(ee_pdm_file))

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when the bypass label is present and applied by an authorized group member' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [described_class::BYPASS_LABEL] }

      before do
        allow(pdm).to receive(:bypass_label_applier).and_return('release-manager-user')
        allow(pdm).to receive(:member_of_authorized_group?)
          .with('release-manager-user').and_return(true)
      end

      it 'warns (allows the MR through) and does not remove the label', :aggregate_failures do
        expect(pdm).to receive(:warn).with(
          a_string_including('exception approved by @release-manager-user')
        )
        expect(pdm).not_to receive(:remove_bypass_label)
        expect(pdm).not_to receive(:fail)

        pdm.check_security_post_deployment_migrations
      end

      it 'posts an approval audit discussion naming the applier and files' do
        expect(pdm).to receive(:post_audit_discussion).with(
          a_string_including('bypass approved').and(
            a_string_including('@release-manager-user')
          ).and(
            a_string_including(pdm_file)
          )
        )

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when the bypass label is present but applied by an unauthorized user' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [described_class::BYPASS_LABEL] }

      before do
        allow(pdm).to receive(:bypass_label_applier).and_return('random-mr-author')
        allow(pdm).to receive(:member_of_authorized_group?)
          .with('random-mr-author').and_return(false)
      end

      it 'removes the bypass label and fails with the unauthorized-applier message' do
        expect(pdm).to receive(:remove_bypass_label).ordered
        expect(pdm).to receive(:fail).ordered.with(
          a_string_including('@random-mr-author').and(
            a_string_including('has been removed')
          )
        )

        pdm.check_security_post_deployment_migrations
      end

      it 'posts a rejection audit discussion before removing the label' do
        allow(pdm).to receive(:fail)

        expect(pdm).to receive(:post_audit_discussion).ordered.with(
          a_string_including('bypass attempt').and(
            a_string_including('@random-mr-author')
          )
        )
        expect(pdm).to receive(:remove_bypass_label).ordered

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when the bypass label is present but the applier cannot be determined' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [described_class::BYPASS_LABEL] }

      before do
        allow(pdm).to receive(:bypass_label_applier).and_return(nil)
      end

      it 'fails closed without removing the label', :aggregate_failures do
        expect(pdm).not_to receive(:remove_bypass_label)
        expect(pdm).to receive(:fail).with(
          a_string_including('could not be verified').and(
            a_string_including('has NOT been removed')
          )
        )

        pdm.check_security_post_deployment_migrations
      end
    end

    context 'when a verification API call fails' do
      let(:security_mr)   { true }
      let(:changed_files) { [pdm_file] }
      let(:mr_labels)     { [described_class::BYPASS_LABEL] }

      before do
        allow(pdm).to receive(:bypass_label_applier).and_raise(StandardError, 'boom')
      end

      it 'fails closed without removing the label', :aggregate_failures do
        expect(pdm).not_to receive(:remove_bypass_label)
        expect(pdm).to receive(:fail).with(
          a_string_including('verification API call failed').and(
            a_string_including('has NOT been removed')
          )
        )

        pdm.check_security_post_deployment_migrations
      end
    end
  end
end
