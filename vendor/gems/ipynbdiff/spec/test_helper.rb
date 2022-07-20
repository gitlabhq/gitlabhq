BASE_PATH = File.join(File.expand_path(File.dirname(__FILE__)),  'testdata')

FROM_PATH = File.join(BASE_PATH, 'from.ipynb')
TO_PATH = File.join(BASE_PATH, 'to.ipynb')

FROM_IPYNB = File.read(FROM_PATH)
TO_IPYNB = File.read(TO_PATH)

def input_for_test(test_case)
  File.join(BASE_PATH, test_case, 'input.ipynb')
end

def expected_symbols(test_case)
  File.join(BASE_PATH, test_case, 'expected_symbols.txt')
end

def expected_md(test_case)
  File.join(BASE_PATH, test_case, 'expected.md')
end

def expected_line_numbers(test_case)
  File.join(BASE_PATH, test_case, 'expected_line_numbers.txt')
end
