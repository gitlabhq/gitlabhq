# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metrics::PatchedFilesWorker, feature_category: :delivery do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    let(:mock_redis) { instance_double(Redis) }

    before do
      allow(Gitlab::Redis::SharedState).to receive(:with).and_yield(mock_redis)
      allow(mock_redis).to receive(:set)
    end

    it 'does not set a value in redis' do
      perform

      expect(mock_redis).not_to have_received(:set)
    end

    describe 'when rpm returns some data' do
      let(:cmd_output) do
        <<~OUTPUT
          S.5....T.    /opt/gitlab/embedded/cookbooks/gitlab-pages/libraries/gitlab_pages.rb
          ..?......    /opt/gitlab/embedded/lib/ruby/gems/3.2.0/gems/ruby-fogbugz-0.3.0/.codeclimate.yml
          S.5....T.    /opt/gitlab/embedded/service/gitlab-rails/app/views/projects/issues/_details_content.html.haml
          .....U...    /opt/gitlab/embedded/service/gitlab-rails/db/structure.sql
        OUTPUT
      end

      before do
        package_name = Gitlab.ee? ? 'gitlab-ee' : 'gitlab-ce'
        allow(Open3).to receive(:capture2).with("rpm --verify #{package_name}").and_return([cmd_output, nil])
      end

      it 'sets the expected value in redis' do
        expected_value = <<~OUTPUT
          S.5....T.    /opt/gitlab/embedded/cookbooks/gitlab-pages/libraries/gitlab_pages.rb
          S.5....T.    /opt/gitlab/embedded/service/gitlab-rails/app/views/projects/issues/_details_content.html.haml
        OUTPUT

        perform

        expect(mock_redis).to have_received(:set).with(described_class::REDIS_KEY, expected_value)
      end
    end
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky
end
