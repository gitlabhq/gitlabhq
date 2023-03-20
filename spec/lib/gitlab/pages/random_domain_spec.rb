# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Pages::RandomDomain, feature_category: :pages do
  let(:namespace_path) { 'namespace' }

  subject(:generator) do
    described_class.new(project_path: project_path, namespace_path: namespace_path)
  end

  RSpec.shared_examples 'random domain' do |domain|
    it do
      expect(SecureRandom)
        .to receive(:hex)
        .and_wrap_original do |_, size, _|
          ('h' * size)
        end

      generated = generator.generate

      expect(generated).to eq(domain)
      expect(generated.length).to eq(63)
    end
  end

  context 'when project path is less than 48 chars' do
    let(:project_path) { 'p' }

    it_behaves_like 'random domain', 'p-namespace-hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh'
  end

  context 'when project path is close to 48 chars' do
    let(:project_path) { 'p' * 45 }

    it_behaves_like 'random domain', 'ppppppppppppppppppppppppppppppppppppppppppppp-na-hhhhhhhhhhhhhh'
  end

  context 'when project path is larger than 48 chars' do
    let(:project_path) { 'p' * 49 }

    it_behaves_like 'random domain', 'pppppppppppppppppppppppppppppppppppppppppppppppp-hhhhhhhhhhhhhh'
  end
end
