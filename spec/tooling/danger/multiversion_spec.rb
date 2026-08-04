# frozen_string_literal: true

require 'rspec-parameterized'
require 'fast_spec_helper'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/multiversion'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::Multiversion, feature_category: :shared do
  include_context "with dangerfile"

  subject(:multiversion) { fake_danger.new(helper: fake_helper, git: fake_git) }

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:ci_env) { true }

  before do
    allow(fake_helper).to receive(:ci?).and_return(ci_env)
    allow(fake_git).to receive(:modified_files).and_return(modified_files)
    allow(fake_git).to receive(:added_files).and_return(added_files)
  end

  describe '#check!' do
    using RSpec::Parameterized::TableSyntax

    context 'when GraphQL API and frontend assets have not been simultaneously updated' do
      where(:modified_files, :added_files) do
        %w[app/assets/helloworld.vue]     | %w[]
        %w[app/assets/helloworld.vue]     | %w[app/type.rb]
        %w[app/assets/helloworld.js]      | %w[app/graphql.rb]
        %w[app/assets/helloworld.graphql] | %w[app/models/graphql.rb]
        %w[]                              | %w[app/graphql/type.rb]
        %w[app/vue.txt] | %w[app/graphql/type.rb]
        %w[app/views/foo.haml] | %w[app/graphql/type.rb]
        %w[foo] | %w[]
        %w[] | %w[]
        # Client-side query documents are frontend-only, so they never satisfy both sides alone.
        %w[app/graphql/queries/snippet/snippet.query.graphql] | %w[]
        %w[] | %w[ee/app/graphql/queries/analytics/foo.query.graphql]
        %w[app/assets/helloworld.vue app/graphql/queries/snippet/snippet.query.graphql] | %w[]
        # A schema change on its own, without any frontend change.
        %w[doc/api/graphql/reference/_index.md] | %w[]
        %w[app/assets/javascripts/graphql_shared/possible_types.json] | %w[]
        %w[app/models/users/callout.rb doc/api/graphql/reference/_index.md] | %w[]
      end

      with_them do
        it 'does not add the warning markdown section' do
          expect(multiversion).not_to receive(:markdown)
          expect(multiversion).not_to receive(:warn)

          multiversion.check!
        end
      end
    end

    context 'when GraphQL API and frontend assets have been simultaneously updated' do
      where(:modified_files, :added_files) do
        %w[app/assets/helloworld.vue]        | %w[app/graphql/type.rb]
        %w[app/assets/helloworld.vue]        | %w[app/graphql/type.rb]
        %w[app/assets/helloworld.js]         | %w[app/graphql/type.rb]
        %w[ee/app/assets/helloworld.js]      | %w[app/graphql/type.rb]
        %w[app/assets/helloworld.graphql]    | %w[ee/app/graphql/type.rb]
        %w[ee/app/assets/helloworld.graphql] | %w[ee/app/graphql/type.rb]
        %w[ee/app/assets/helloworld.graphql] | %w[jh/app/graphql/type.rb]
        # A client-side query document consuming a new field from the backend.
        %w[app/graphql/queries/snippet/snippet.query.graphql] | %w[app/graphql/types/snippet_type.rb]
        %w[ee/app/graphql/queries/analytics/foo.query.graphql] | %w[ee/app/graphql/types/foo_type.rb]
        # A schema change whose source lives outside app/graphql, surfaced by the generated files.
        %w[app/models/users/callout.rb doc/api/graphql/reference/_index.md app/assets/foo.vue] | %w[]
        %w[app/assets/helloworld.vue app/assets/javascripts/graphql_shared/possible_types.json] | %w[]
        %w[app/assets/helloworld.vue] | %w[doc/api/graphql/reference/_index.md]
      end

      with_them do
        it 'adds the warning markdown section' do
          expect(multiversion).to receive(:markdown)
          expect(multiversion).to receive(:warn).with(described_class::WARNING)

          multiversion.check!
        end
      end
    end

    context 'when running outside ci' do
      let(:ci_env) { false }
      let(:modified_files) { %w[app/assets/helloworld.vue] }
      let(:added_files) { %w[app/graphql/type.rb] }

      it 'tells the author how to compare against a target branch other than master' do
        expect(multiversion).to receive(:markdown)
        expect(multiversion).to receive(:warn)
          .with("#{described_class::WARNING} #{described_class::LOCAL_BASE_HINT}")

        multiversion.check!
      end
    end
  end
end
