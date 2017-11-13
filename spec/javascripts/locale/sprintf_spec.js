import sprintf from '~/locale/sprintf';

describe('locale', () => {
  describe('sprintf', () => {
    it('does not modify string without parameters', () => {
      const input = 'No parameters';

      const output = sprintf(input);

      expect(output).toBe(input);
    });

    it('ignores extraneous parameters', () => {
      const input = 'No parameters';

      const output = sprintf(input, { ignore: 'this' });

      expect(output).toBe(input);
    });

    it('ignores extraneous placeholders', () => {
      const input = 'No %{parameters}';

      const output = sprintf(input);

      expect(output).toBe(input);
    });

    it('replaces parameters', () => {
      const input = '%{name} has %{count} parameters';
      const parameters = {
        name: 'this',
        count: 2,
      };

      const output = sprintf(input, parameters);

      expect(output).toBe('this has 2 parameters');
    });

    it('replaces multiple occurrences', () => {
      const input = 'to %{verb} or not to %{verb}';
      const parameters = {
        verb: 'be',
      };

      const output = sprintf(input, parameters);

      expect(output).toBe('to be or not to be');
    });

    it('escapes parameters', () => {
      const input = 'contains %{userContent}';
      const parameters = {
        userContent: '<script>alert("malicious!")</script>',
      };

      const output = sprintf(input, parameters);

      expect(output).toBe('contains &lt;script&gt;alert(&quot;malicious!&quot;)&lt;/script&gt;');
    });

    it('does not escape parameters for escapeParameters = false', () => {
      const input = 'contains %{safeContent}';
      const parameters = {
        safeContent: '<strong>bold attempt</strong>',
      };

      const output = sprintf(input, parameters, false);

      expect(output).toBe('contains <strong>bold attempt</strong>');
    });
  });
});
