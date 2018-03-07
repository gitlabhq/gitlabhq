export default {
  'protocol-based JS injection: simple, no spaces': {
    input: '<a href="javascript:alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: simple, spaces before': {
    input: '<a href="javascript    :alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: simple, spaces after': {
    input: '<a href="javascript:    alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: simple, spaces before and after': {
    input: '<a href="javascript    :   alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: preceding colon': {
    input: '<a href=":javascript:alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: UTF-8 encoding': {
    input: '<a href="javascript&#58;">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: long UTF-8 encoding': {
    input: '<a href="javascript&#0058;">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: long UTF-8 encoding without semicolons': {
    input: '<a href=&#0000106&#0000097&#0000118&#0000097&#0000115&#0000099&#0000114&#0000105&#0000112&#0000116&#0000058&#0000097&#0000108&#0000101&#0000114&#0000116&#0000040&#0000039&#0000088&#0000083&#0000083&#0000039&#0000041>foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: hex encoding': {
    input: '<a href="javascript&#x3A;">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: long hex encoding': {
    input: '<a href="javascript&#x003A;">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: hex encoding without semicolons': {
    input: '<a href=&#x6A&#x61&#x76&#x61&#x73&#x63&#x72&#x69&#x70&#x74&#x3A&#x61&#x6C&#x65&#x72&#x74&#x28&#x27&#x58&#x53&#x53&#x27&#x29>foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: null char': {
    input: '<a href=java\0script:alert("XSS")>foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: invalid URL char': {
    input: '<img src=java\script:alert("XSS")>', // eslint-disable-line no-useless-escape
    output: '<img>',
  },
  'protocol-based JS injection: Unicode': {
    input: '<a href="\u0001java\u0003script:alert(\'XSS\')">foo</a>',
    output: '<a>foo</a>',
  },
  'protocol-based JS injection: spaces and entities': {
    input: '<a href=" &#14;  javascript:alert(\'XSS\');">foo</a>',
    output: '<a>foo</a>',
  },
  'img on error': {
    input: '<img src="x" onerror="alert(document.domain)" />',
    output: '<img src="x">',
  },
};
