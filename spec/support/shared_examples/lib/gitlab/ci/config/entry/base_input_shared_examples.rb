# frozen_string_literal: true

RSpec.shared_examples 'BaseInput' do
  context 'with string type' do
    let(:config) { { type: 'string' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with number type' do
    let(:config) { { type: 'number' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with boolean type' do
    let(:config) { { type: 'boolean' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with array type' do
    let(:config) { { type: 'array' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with description' do
    let(:config) { { description: 'A helpful description' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with options' do
    let(:config) { { options: %w[option1 option2] }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with regex' do
    let(:config) { { regex: '^v\d+\.\d+\.\d+$' }.merge(required_config) }

    it 'is valid' do
      expect(entry).to be_valid
    end
  end

  context 'with invalid type' do
    let(:config) { { type: 'invalid_type' }.merge(required_config) }

    it 'reports error about invalid type' do
      expect(entry).not_to be_valid
      expect(entry.errors.join).to include('input type unknown value: invalid_type')
    end
  end

  context 'when options is not an array' do
    let(:config) { { options: 'not_an_array' }.merge(required_config) }

    it 'reports error about invalid options' do
      expect(entry).not_to be_valid
      expect(entry.errors.join).to include('options should be an array')
    end
  end

  context 'when options exceed limit' do
    let(:config) { { options: (1..51).to_a }.merge(required_config) }

    it 'reports error about exceeding limit' do
      expect(entry).not_to be_valid
      expect(entry.errors.join).to include('cannot define more than 50 options')
    end
  end

  context 'when regex is not a string' do
    let(:config) { { regex: 123 }.merge(required_config) }

    it 'reports error about invalid regex' do
      expect(entry).not_to be_valid
      expect(entry.errors.join).to include('regex should be a string')
    end
  end

  context 'with unknown keys' do
    let(:config) { { unknown_key: 'value' }.merge(required_config) }

    it 'reports error about unknown keys' do
      expect(entry).not_to be_valid
      expect(entry.errors.join).to include('contains unknown keys: unknown_key')
    end
  end
end
