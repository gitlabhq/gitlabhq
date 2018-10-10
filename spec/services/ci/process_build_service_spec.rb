# frozen_string_literal: true
require 'spec_helper'

describe Ci::ProcessBuildService, '#execute' do
  VALID_STATUSES_WHEN_ON_SUCCESS = %w[success skipped].freeze
  VALID_STATUSES_WHEN_ON_FAILURE = %w[failed].freeze
  VALID_STATUSES_WHEN_ALWAYS = %w[success failed skipped].freeze
  VALID_STATUSES_WHEN_MANUAL = %w[success skipped].freeze
  VALID_STATUSES_WHEN_DELAYED = %w[success skipped].freeze
  SKIPPABLE_STATUES = %w[created pending].freeze

  let(:user) { create(:user) }
  let(:project) { create(:project) }

  subject { described_class.new(project, user).execute(build, status_for_prior_stages) }

  before do
    project.add_maintainer(user)
  end

  shared_examples_for 'Change the build status' do |when_option: nil, current_statuses: nil, from_statuses:, to_status:, factory_options: nil|
    current_statuses.each do |current_status|
      context "when status for prior stages is #{current_status}" do
        let(:status_for_prior_stages) { current_status }

        from_statuses.each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, *factory_options, when: when_option, user: user, project: project) }

            it 'changes the build status' do
              expect { subject }.to change { build.status }.to(to_status)
            end
          end
        end

        (HasStatus::AVAILABLE_STATUSES - from_statuses).each do |status|
          context "when build status is #{status}" do
            let(:build) { create(:ci_build, status.to_sym, *factory_options, when: when_option, user: user, project: project) }

            it 'does not change the build status' do
              expect { subject }.not_to change { build.status }
            end
          end
        end
      end
    end
  end

  context 'when build has on_success option' do
    it_behaves_like 'Change the build status',
      when_option: :on_success,
      current_statuses: VALID_STATUSES_WHEN_ON_SUCCESS,
      from_statuses: %w[created skipped manual scheduled],
      to_status: 'pending'

    it_behaves_like 'Change the build status',
      when_option: :on_success,
      current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ON_SUCCESS),
      from_statuses: SKIPPABLE_STATUES,
      to_status: 'skipped'
  end

  context 'when build has on_failure option' do
    it_behaves_like 'Change the build status',
      when_option: :on_failure,
      current_statuses: VALID_STATUSES_WHEN_ON_FAILURE,
      from_statuses: %w[created skipped manual scheduled],
      to_status: 'pending'

    it_behaves_like 'Change the build status',
      when_option: :on_failure,
      current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ON_FAILURE),
      from_statuses: SKIPPABLE_STATUES,
      to_status: 'skipped'
  end

  context 'when build has always option' do
    it_behaves_like 'Change the build status',
      when_option: :always,
      current_statuses: VALID_STATUSES_WHEN_ALWAYS,
      from_statuses: %w[created skipped manual scheduled],
      to_status: 'pending'

    it_behaves_like 'Change the build status',
      when_option: :always,
      current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ALWAYS),
      from_statuses: SKIPPABLE_STATUES,
      to_status: 'skipped'
  end

  context 'when build has manual option' do
    it_behaves_like 'Change the build status',
      when_option: :manual,
      current_statuses: VALID_STATUSES_WHEN_MANUAL,
      from_statuses: %w[created],
      to_status: 'manual',
      factory_options: %i[actionable]

    it_behaves_like 'Change the build status',
      when_option: :manual,
      current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ON_SUCCESS),
      from_statuses: SKIPPABLE_STATUES,
      to_status: 'skipped',
      factory_options: %i[actionable]
  end

  context 'when build has delayed option' do
    before do
      allow(Ci::BuildScheduleWorker).to receive(:perform_at) { }
    end

    context 'when ci_enable_scheduled_build is enabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: true)
      end

      it_behaves_like 'Change the build status',
        when_option: :delayed,
        current_statuses: VALID_STATUSES_WHEN_DELAYED,
        from_statuses: %w[created],
        to_status: 'scheduled',
        factory_options: %i[schedulable]

      it_behaves_like 'Change the build status',
        when_option: :delayed,
        current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ON_SUCCESS),
        from_statuses: SKIPPABLE_STATUES,
        to_status: 'skipped',
        factory_options: %i[schedulable]
    end

    context 'when ci_enable_scheduled_build is enabled' do
      before do
        stub_feature_flags(ci_enable_scheduled_build: false)
      end

      it_behaves_like 'Change the build status',
        when_option: :delayed,
        current_statuses: VALID_STATUSES_WHEN_DELAYED,
        from_statuses: %w[created],
        to_status: 'manual',
        factory_options: %i[schedulable]

      it_behaves_like 'Change the build status',
        when_option: :delayed,
        current_statuses: (HasStatus::AVAILABLE_STATUSES - VALID_STATUSES_WHEN_ON_SUCCESS),
        from_statuses: SKIPPABLE_STATUES,
        to_status: 'skipped',
        factory_options: %i[schedulable]
    end
  end
end
