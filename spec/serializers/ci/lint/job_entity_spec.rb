# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Lint::JobEntity, :aggregate_failures do
  describe '#represent' do
    let(:job) do
      {
        name: 'rspec',
        stage: 'test',
        before_script: ['bundle install', 'bundle exec rake db:create'],
        script: ["rake spec"],
        after_script: ["rake spec"],
        tag_list: %w[ruby postgres],
        environment: { name: 'hello', url: 'world' },
        when: 'on_success',
        allow_failure: false,
        except: { refs: ["branches"] },
        only: { refs: ["branches"] },
        variables: { hello: 'world' }
      }
    end

    subject(:serialized_job_result) { described_class.new(job).as_json }

    it 'exposes job data' do
      expect(serialized_job_result.keys).to contain_exactly(
        :name,
        :stage,
        :before_script,
        :script,
        :after_script,
        :tag_list,
        :environment,
        :when,
        :allow_failure,
        :only,
        :except
      )
      expect(serialized_job_result.keys).not_to include(:variables)
    end
  end
end
