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

    context 'when not in ci environment' do
      let(:ci_env) { false }

      it 'does not add the warning markdown section' do
        expect(multiversion).not_to receive(:markdown)

        multiversion.check!
      end
    end

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
      end

      with_them do
        it 'does not add the warning markdown section' do
          expect(multiversion).not_to receive(:markdown)

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
      end

      with_them do
        it 'adds the warning markdown section' do
          expect(multiversion).to receive(:markdown)

          multiversion.check!
        end
      end
    end
  end
end
