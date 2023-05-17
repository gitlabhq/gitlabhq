# frozen_string_literal: true

RSpec.shared_examples 'Gitlab-style deprecations' do
  describe 'validations' do
    it 'raises an informative error if `deprecation_reason` is used' do
      expect { subject(deprecation_reason: 'foo') }.to raise_error(
        ArgumentError,
        start_with('Use `deprecated` property instead of `deprecation_reason`.')
      )
    end

    it 'raises an error if a required property is missing', :aggregate_failures do
      expect { subject(deprecated: { milestone: '1.10' }) }.to raise_error(
        ArgumentError,
        include("Reason can't be blank")
      )
      expect { subject(deprecated: { reason: 'Deprecation reason' }) }.to raise_error(
        ArgumentError,
        include("Milestone can't be blank")
      )
    end

    it 'raises an error if milestone is not a String', :aggregate_failures do
      expect { subject(deprecated: { milestone: 1.10, reason: 'Deprecation reason' }) }.to raise_error(
        ArgumentError,
        include("Milestone must be a string")
      )
    end
  end

  it 'adds a formatted `deprecated_reason` to the subject' do
    deprecable = subject(deprecated: { milestone: '1.10', reason: 'Deprecation reason' })

    expect(deprecable.deprecation_reason).to eq('Deprecation reason. Deprecated in 1.10.')
  end

  it 'appends to the description if given' do
    deprecable = subject(
      deprecated: { milestone: '1.10', reason: 'Deprecation reason' },
      description: 'Deprecable description.'
    )

    expect(deprecable.description).to eq('Deprecable description. Deprecated in 1.10: Deprecation reason.')
  end

  it 'does not append to the description if it is absent' do
    deprecable = subject(deprecated: { milestone: '1.10', reason: 'Deprecation reason' })

    expect(deprecable.description).to be_nil
  end

  it 'adds information about the replacement if provided' do
    deprecable = subject(deprecated: { milestone: '1.10', reason: :renamed, replacement: 'Foo.bar' })

    expect(deprecable.deprecation_reason).to include('Please use `Foo.bar`')
  end

  it 'supports named reasons: renamed' do
    deprecable = subject(deprecated: { milestone: '1.10', reason: :renamed })

    expect(deprecable.deprecation_reason).to eq('This was renamed. Deprecated in 1.10.')
  end

  it 'supports named reasons: alpha' do
    deprecable = subject(deprecated: { milestone: '1.10', reason: :alpha })

    expect(deprecable.deprecation_reason).to eq(
      'This feature is an Experiment. It can be changed or removed at any time. Introduced in 1.10.'
    )
  end

  it 'supports :alpha' do
    deprecable = subject(alpha: { milestone: '1.10' })

    expect(deprecable.deprecation_reason).to eq(
      'This feature is an Experiment. It can be changed or removed at any time. Introduced in 1.10.'
    )
  end

  it 'does not allow :alpha and :deprecated together' do
    expect do
      subject(alpha: { milestone: '1.10' }, deprecated: { milestone: '1.10', reason: 'my reason' } )
    end.to raise_error(
      ArgumentError,
      eq("`experiment` and `deprecated` arguments cannot be passed at the same time")
    )
  end

  describe 'visible?' do
    let(:ctx) { {} }

    it 'defaults to true' do
      expect(subject).to be_visible(ctx)
    end

    context 'when subject is deprecated' do
      let(:arguments) { { deprecated: { milestone: '1.10', reason: :renamed } } }

      it 'defaults to true' do
        expect(subject(arguments)).to be_visible(ctx)
      end

      it 'returns false if `remove_deprecated` is true in context' do
        ctx = { remove_deprecated: true }
        expect(subject(arguments)).not_to be_visible(ctx)
      end
    end
  end
end
