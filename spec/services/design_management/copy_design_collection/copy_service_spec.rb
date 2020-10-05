# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::CopyDesignCollection::CopyService, :clean_gitlab_redis_shared_state do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue, refind: true) { create(:issue, project: project) }
  let(:target_issue) { create(:issue) }

  subject { described_class.new(project, user, issue: issue, target_issue: target_issue).execute }

  before do
    enable_design_management
  end

  shared_examples 'service error' do |message:|
    it 'returns an error response', :aggregate_failures do
      expect(subject).to be_kind_of(ServiceResponse)
      expect(subject).to be_error
      expect(subject.message).to eq(message)
    end
  end

  shared_examples 'service success' do
    it 'returns a success response', :aggregate_failures do
      expect(subject).to be_kind_of(ServiceResponse)
      expect(subject).to be_success
    end
  end

  include_examples 'service error', message: 'User cannot copy design collection to issue'

  context 'when user has permission to read the design collection' do
    before_all do
      project.add_reporter(user)
    end

    include_examples 'service error', message: 'User cannot copy design collection to issue'

    context 'when the user also has permission to admin the target issue' do
      let(:target_repository) { target_issue.project.design_repository }

      before do
        target_issue.project.add_reporter(user)
      end

      include_examples 'service error', message: 'Target design collection must first be queued'

      context 'when the target design collection has been queued' do
        before do
          target_issue.design_collection.start_copy!
        end

        include_examples 'service error', message: 'Design collection has no designs'

        context 'when design collection has designs' do
          let_it_be(:designs) do
            create_list(:design, 3, :with_lfs_file, :with_relative_position, issue: issue, project: project)
          end

          context 'when target issue already has designs' do
            before do
              create(:design, issue: target_issue, project: target_issue.project)
            end

            include_examples 'service error', message: 'Target design collection already has designs'
          end

          include_examples 'service success'

          it 'creates a design repository for the target project' do
            expect { subject }.to change { target_repository.exists? }.from(false).to(true)
          end

          context 'when the target project already has a design repository' do
            before do
              target_repository.create_if_not_exists
            end

            include_examples 'service success'
          end

          it 'copies the designs correctly', :aggregate_failures do
            expect { subject }.to change { target_issue.designs.count }.by(3)

            old_designs = issue.designs.ordered
            new_designs = target_issue.designs.ordered

            new_designs.zip(old_designs).each do |new_design, old_design|
              expect(new_design).to have_attributes(
                filename: old_design.filename,
                relative_position: old_design.relative_position,
                issue: target_issue,
                project: target_issue.project
              )
            end
          end

          it 'copies the design versions correctly', :aggregate_failures do
            expect { subject }.to change { target_issue.design_versions.count }.by(3)

            old_versions = issue.design_versions.ordered
            new_versions = target_issue.design_versions.ordered

            new_versions.zip(old_versions).each do |new_version, old_version|
              expect(new_version).to have_attributes(
                created_at: old_version.created_at,
                author_id: old_version.author_id
              )
              expect(new_version.designs.pluck(:filename)).to eq(old_version.designs.pluck(:filename))
              expect(new_version.actions.pluck(:event)).to eq(old_version.actions.pluck(:event))
            end
          end

          it 'copies the design actions correctly', :aggregate_failures do
            expect { subject }.to change { DesignManagement::Action.count }.by(3)

            old_actions = issue.design_versions.ordered.flat_map(&:actions)
            new_actions = target_issue.design_versions.ordered.flat_map(&:actions)

            new_actions.zip(old_actions).each do |new_action, old_action|
              # This is a way to identify if the versions linked to the actions
              # are correct is to compare design filenames, as the SHA changes.
              new_design_filenames = new_action.version.designs.ordered.pluck(:filename)
              old_design_filenames = old_action.version.designs.ordered.pluck(:filename)

              expect(new_design_filenames).to eq(old_design_filenames)
              expect(new_action.event).to eq(old_action.event)
              expect(new_action.design.filename).to eq(old_action.design.filename)
            end
          end

          it 'copies design notes correctly', :aggregate_failures, :sidekiq_inline do
            old_notes = [
              create(:diff_note_on_design, note: 'first note', noteable: designs.first, project: project, author: create(:user)),
              create(:diff_note_on_design, note: 'second note', noteable: designs.first, project: project, author: create(:user))
            ]
            matchers = old_notes.map do |note|
              have_attributes(
                note.attributes.slice(
                  :type,
                  :author_id,
                  :note,
                  :position
                )
              )
            end

            expect { subject }.to change { Note.count }.by(2)

            new_notes = target_issue.designs.first.notes.fresh

            expect(new_notes).to match_array(matchers)
          end

          it 'links the LfsObjects' do
            expect { subject }.to change { target_issue.project.lfs_objects.count }.by(3)
          end

          it 'copies the Git repository data', :aggregate_failures do
            subject

            commit_shas = target_repository.commits('master', limit: 99).map(&:id)

            expect(commit_shas).to include(*target_issue.design_versions.ordered.pluck(:sha))
          end

          it 'creates a master branch if none previously existed' do
            expect { subject }.to change { target_repository.branch_names }.from([]).to(['master'])
          end

          it 'leaves the design collection in the correct copy state' do
            subject

            expect(target_issue.design_collection).to be_copy_ready
          end

          describe 'rollback' do
            before do
              # Ensure the very last step throws an error
              expect_next_instance_of(described_class) do |service|
                expect(service).to receive(:finalize!).and_raise
              end
            end

            include_examples 'service error', message: 'Designs were unable to be copied successfully'

            it 'rollsback all PostgreSQL data created', :aggregate_failures do
              expect { subject }.not_to change {
                [
                  DesignManagement::Design.count,
                  DesignManagement::Action.count,
                  DesignManagement::Version.count,
                  Note.count
                ]
              }

              collections = [
                target_issue.design_collection,
                target_issue.designs,
                target_issue.design_versions
              ]

              expect(collections).to all(be_empty)
            end

            it 'does not alter master branch', :aggregate_failures do
              # Add some Git data to the target_repository, so we are testing
              # that any original data remains
              issue_2 = create(:issue, project: target_issue.project)
              create(:design, :with_file, issue: issue_2, project: target_issue.project)

              expect { subject }.not_to change {
                expect(target_repository.commits('master', limit: 10).size).to eq(1)
              }
            end

            it 'sets the design collection copy state' do
              subject

              expect(target_issue.design_collection).to be_copy_error
            end
          end
        end
      end
    end
  end

  describe 'Alert if schema changes', :aggregate_failures do
    let_it_be(:config_file) { Rails.root.join('lib/gitlab/design_management/copy_design_collection_model_attributes.yml') }
    let_it_be(:config) { YAML.load_file(config_file).symbolize_keys }

    %w(Design Action Version).each do |model|
      specify do
        attributes = config["#{model.downcase}_attributes".to_sym] || []
        ignored_attributes = config["ignore_#{model.downcase}_attributes".to_sym]

        expect(attributes + ignored_attributes).to contain_exactly(
          *DesignManagement.const_get(model, false).column_names
        ), failure_message(model)
      end
    end

    def failure_message(model)
      <<-MSG
      The schema of the `#{model}` model has changed.

      `#{described_class.name}` refers to specific lists of attributes of `#{model}` to either
      copy or ignore, so that we continue to copy designs correctly after schema changes.

      Please update:
      #{config_file}
      to reflect the latest changes to `#{model}`. See that file for more information.
      MSG
    end
  end
end
