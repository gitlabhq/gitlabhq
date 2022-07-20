# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillCiRunnerSemver, :migration, schema: 20220601151900 do
  let(:ci_runners) { table(:ci_runners, database: :ci) }

  subject do
    described_class.new(
      start_id: 10,
      end_id: 15,
      batch_table: :ci_runners,
      batch_column: :id,
      sub_batch_size: 10,
      pause_ms: 0,
      connection: Ci::ApplicationRecord.connection)
  end

  describe '#perform' do
    it 'populates semver column on all runners in range' do
      ci_runners.create!(id: 10, runner_type: 1, version: %q(HEAD-fd84d97))
      ci_runners.create!(id: 11, runner_type: 1, version: %q(v1.2.3))
      ci_runners.create!(id: 12, runner_type: 1, version: %q(2.1.0))
      ci_runners.create!(id: 13, runner_type: 1, version: %q(11.8.0~beta.935.g7f6d2abc))
      ci_runners.create!(id: 14, runner_type: 1, version: %q(13.2.2/1.1.0))
      ci_runners.create!(id: 15, runner_type: 1, version: %q('14.3.4'))

      subject.perform

      expect(ci_runners.all).to contain_exactly(
        an_object_having_attributes(id: 10, semver: nil),
        an_object_having_attributes(id: 11, semver: '1.2.3'),
        an_object_having_attributes(id: 12, semver: '2.1.0'),
        an_object_having_attributes(id: 13, semver: '11.8.0'),
        an_object_having_attributes(id: 14, semver: '13.2.2'),
        an_object_having_attributes(id: 15, semver: '14.3.4')
      )
    end

    it 'skips runners that already have semver value' do
      ci_runners.create!(id: 10, runner_type: 1, version: %q(1.2.4), semver: '1.2.3')
      ci_runners.create!(id: 11, runner_type: 1, version: %q(1.2.5))
      ci_runners.create!(id: 12, runner_type: 1, version: %q(HEAD), semver: '1.2.4')

      subject.perform

      expect(ci_runners.all).to contain_exactly(
        an_object_having_attributes(id: 10, semver: '1.2.3'),
        an_object_having_attributes(id: 11, semver: '1.2.5'),
        an_object_having_attributes(id: 12, semver: '1.2.4')
      )
    end
  end
end
