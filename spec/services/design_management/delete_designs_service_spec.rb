# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::DeleteDesignsService do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  let(:designs) { create_designs }

  subject(:service) { described_class.new(project, user, issue: issue, designs: designs) }

  # Defined as a method so that the reponse is not cached. We also construct
  # a new service executor each time to avoid the intermediate cached values
  # it constructs during its execution.
  def run_service(delenda = nil)
    service = described_class.new(project, user, issue: issue, designs: delenda || designs)
    service.execute
  end

  let(:response) { run_service }

  shared_examples 'a service error' do
    it 'returns an error', :aggregate_failures do
      expect(response).to include(status: :error)
    end
  end

  shared_examples 'a top-level error' do
    let(:expected_error) { StandardError }
    it 'raises an en expected error', :aggregate_failures do
      expect { run_service }.to raise_error(expected_error)
    end
  end

  shared_examples 'a success' do
    it 'returns successfully', :aggregate_failures do
      expect(response).to include(status: :success)
    end

    it 'saves the user as the author' do
      version = response[:version]

      expect(version.author).to eq(user)
    end
  end

  before do
    enable_design_management(enabled)
    project.add_developer(user)
  end

  describe "#execute" do
    context "when the feature is not available" do
      let(:enabled) { false }

      it_behaves_like "a service error"

      it 'does not create any events in the activity stream' do
        expect { run_service rescue nil }.not_to change { Event.count }
      end
    end

    context "when the feature is available" do
      let(:enabled) { true }

      it 'is able to delete designs' do
        expect(service.send(:can_delete_designs?)).to be true
      end

      context 'no designs were passed' do
        let(:designs) { [] }

        it_behaves_like "a top-level error"

        it 'does not log any events' do
          counter = ::Gitlab::UsageDataCounters::DesignsCounter

          expect { run_service rescue nil }
            .not_to change { [counter.totals, Event.count] }
        end

        it 'does not log any UsageData metrics' do
          redis_hll = ::Gitlab::UsageDataCounters::HLLRedisCounter
          event = Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_DESIGNS_REMOVED

          expect { run_service rescue nil }
            .not_to change { redis_hll.unique_events(event_names: event, start_date: 1.day.ago, end_date: 1.day.from_now) }

          run_service rescue nil
        end
      end

      context 'one design is passed' do
        before do
          create_designs(2)
        end

        let!(:designs) { create_designs(1) }

        it 'removes that design' do
          expect { run_service }.to change { issue.designs.current.count }.from(3).to(2)
        end

        it 'logs a deletion event' do
          counter = ::Gitlab::UsageDataCounters::DesignsCounter
          expect { run_service }.to change { counter.read(:delete) }.by(1)
        end

        it 'updates UsageData for removed designs' do
          expect(Gitlab::UsageDataCounters::IssueActivityUniqueCounter).to receive(:track_issue_designs_removed_action).with(author: user)

          run_service
        end

        it 'creates an event in the activity stream' do
          expect { run_service }
            .to change { Event.count }.by(1)
            .and change { Event.destroyed_action.for_design.count }.by(1)
        end

        it 'informs the new-version-worker' do
          expect(::DesignManagement::NewVersionWorker).to receive(:perform_async).with(Integer, false)

          run_service
        end

        it 'creates a new version' do
          expect { run_service }.to change { DesignManagement::Version.where(issue: issue).count }.by(1)
        end

        it 'returns the new version' do
          version = response[:version]

          expect(version).to eq(DesignManagement::Version.for_issue(issue).ordered.first)
        end

        it_behaves_like "a success"

        it 'removes the design from the current design list' do
          run_service

          expect(issue.designs.current).not_to include(designs.first)
        end

        it 'marks the design as deleted' do
          expect { run_service }
            .to change { designs.first.deleted? }.from(false).to(true)
        end
      end

      context 'more than one design is passed' do
        before do
          create_designs(1)
        end

        let!(:designs) { create_designs(2) }

        it 'makes the correct changes' do
          counter = ::Gitlab::UsageDataCounters::DesignsCounter

          expect { run_service }
            .to change { issue.designs.current.count }.from(3).to(1)
            .and change { counter.read(:delete) }.by(2)
            .and change { Event.count }.by(2)
            .and change { Event.destroyed_action.for_design.count }.by(2)
        end

        it_behaves_like "a success"

        context 'after executing the service' do
          let(:deleted_designs) { designs.map(&:reset) }

          let!(:version) { run_service[:version] }

          it 'removes the removed designs from the current design list' do
            expect(issue.designs.current).not_to include(*deleted_designs)
          end

          it 'does not make the designs impossible to find' do
            expect(issue.designs).to include(*deleted_designs)
          end

          it 'associates the new version with all the designs' do
            current_versions = deleted_designs.map { |d| d.most_recent_action.version }
            expect(current_versions).to all(eq version)
          end

          it 'marks all deleted designs as deleted' do
            expect(deleted_designs).to all(be_deleted)
          end

          it 'marks all deleted designs with the same deletion version' do
            expect(deleted_designs.map { |d| d.most_recent_action.version_id }.uniq)
              .to have_attributes(size: 1)
          end
        end
      end

      describe 'scalability' do
        before do
          run_service(create_designs(1)) # ensure project, issue, etc are created
        end

        it 'makes the same number of DB requests for one design as for several' do
          one = create_designs(1)
          many = create_designs(5)

          baseline = ActiveRecord::QueryRecorder.new { run_service(one) }

          expect { run_service(many) }.not_to exceed_query_limit(baseline)
        end
      end
    end
  end

  private

  def create_designs(how_many = 2)
    create_list(:design, how_many, :with_lfs_file, issue: issue)
  end
end
