export const baseIssues = [
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 22,
        end: 22,
      },
    },
    fingerprint: 'ca2e59451e98ae60ba2f54e3857c50e5',
  },
  {
    categories: ['Security'],
    check_name: 'Insecure Dependency',
    description: 'Insecure Dependency',
    location: {
      path: 'Gemfile.lock',
      lines: {
        begin: 21,
        end: 21,
      },
    },
    fingerprint: 'ca2354534dee94ae60ba2f54e3857c50e5',
  },
];

export const sastParsedIssues = [
  {
    name: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    line: 12,
    priority: 'High',
    urlPath: 'foo/Gemfile.lock',
  },
];

export const sastIssues = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const sastIssuesBase = [
  {
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
  },
];

export const parsedSastIssuesStore = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    name: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    name: 'Possible Information Leak Vulnerability in Action View',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    name: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
];

export const parsedSastIssuesHead = [
  {
    tool: 'bundler_audit',
    message: 'Arbitrary file existence disclosure in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/rMTQy4oRCGk',
    cve: 'CVE-2014-7829',
    file: 'Gemfile.lock',
    solution: 'upgrade to ~> 3.2.21, ~> 4.0.11.1, ~> 4.0.12, ~> 4.1.7.1, >= 4.1.8',
    name: 'Arbitrary file existence disclosure in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
  {
    tool: 'bundler_audit',
    message: 'Possible Object Leak and Denial of Service attack in Action Pack',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/9oLY_FCzvoc',
    cve: 'CVE-2016-0751',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    name: 'Possible Object Leak and Denial of Service attack in Action Pack',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
];

export const parsedSastBaseStore = [
  {
    name: 'Test Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Test Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-9999',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
];

export const allIssuesParsed = [
  {
    name: 'Possible Information Leak Vulnerability in Action View',
    tool: 'bundler_audit',
    message: 'Possible Information Leak Vulnerability in Action View',
    url: 'https://groups.google.com/forum/#!topic/rubyonrails-security/335P1DcLG00',
    cve: 'CVE-2016-0752',
    file: 'Gemfile.lock',
    solution:
      'upgrade to >= 5.0.0.beta1.1, >= 4.2.5.1, ~> 4.2.5, >= 4.1.14.1, ~> 4.1.14, ~> 3.2.22.1',
    path: 'Gemfile.lock',
    urlPath: 'path/Gemfile.lock',
  },
];

export const dockerReport = {
  unapproved: ['CVE-2017-12944', 'CVE-2017-16232'],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
  ],
};

export const dockerBaseReport = {
  unapproved: ['CVE-2017-12944'],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
    },
  ],
};

export const dockerNewIssues = [
  {
    vulnerability: 'CVE-2017-16232',
    namespace: 'debian:8',
    severity: 'Negligible',
    name: 'CVE-2017-16232',
    priority: 'Negligible',
    path: 'debian:8',
    nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
  },
];

export const dockerOnlyHeadParsed = [
  {
    vulnerability: 'CVE-2017-12944',
    namespace: 'debian:8',
    severity: 'Medium',
    name: 'CVE-2017-12944',
    priority: 'Medium',
    path: 'debian:8',
    nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
  },
  {
    vulnerability: 'CVE-2017-16232',
    namespace: 'debian:8',
    severity: 'Negligible',
    name: 'CVE-2017-16232',
    priority: 'Negligible',
    path: 'debian:8',
    nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
  },
];

export const dockerReportParsed = {
  unapproved: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      name: 'CVE-2017-12944',
      priority: 'Medium',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      name: 'CVE-2017-16232',
      priority: 'Negligible',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
    },
  ],
  approved: [
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      name: 'CVE-2014-8130',
      priority: 'Negligible',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-8130',
    },
  ],
  vulnerabilities: [
    {
      vulnerability: 'CVE-2017-12944',
      namespace: 'debian:8',
      severity: 'Medium',
      name: 'CVE-2017-12944',
      priority: 'Medium',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-12944',
    },
    {
      vulnerability: 'CVE-2017-16232',
      namespace: 'debian:8',
      severity: 'Negligible',
      name: 'CVE-2017-16232',
      priority: 'Negligible',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2017-16232',
    },
    {
      vulnerability: 'CVE-2014-8130',
      namespace: 'debian:8',
      severity: 'Negligible',
      name: 'CVE-2014-8130',
      priority: 'Negligible',
      path: 'debian:8',
      nameLink: 'https://cve.mitre.org/cgi-bin/cvename.cgi?name=CVE-2014-8130',
    },
  ],
};

export const dast = {
  site: {
    alerts: [
      {
        name: 'Absence of Anti-CSRF Tokens',
        riskcode: '1',
        riskdesc: 'Low (Medium)',
        desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
        pluginid: '123',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
          {
            uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
        ],
      },
      {
        alert: 'X-Content-Type-Options Header Missing',
        name: 'X-Content-Type-Options Header Missing',
        riskdesc: 'Low (Medium)',
        desc:
          '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
        pluginid: '3456',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
            method: 'GET',
            param: 'X-Content-Type-Options',
          },
        ],
      },
    ],
  },
};

export const dastBase = {
  site: {
    alerts: [
      {
        name: 'Absence of Anti-CSRF Tokens',
        riskcode: '1',
        riskdesc: 'Low (Medium)',
        desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
        pluginid: '123',
        instances: [
          {
            uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
          {
            uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
            method: 'GET',
            evidence:
              "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
          },
        ],
      },
    ],
  },
};

export const parsedDast = [
  {
    name: 'Absence of Anti-CSRF Tokens',
    riskcode: '1',
    riskdesc: 'Low (Medium)',
    priority: 'Low (Medium)',
    desc: '<p>No Anti-CSRF tokens were found in a HTML submission form.</p>',
    parsedDescription: ' No Anti-CSRF tokens were found in a HTML submission form. ',
    pluginid: '123',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/explore?sort=latest_activity_desc',
        method: 'GET',
        evidence: "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
      },
      {
        uri: 'http://192.168.32.236:3001/help/user/group/subgroups/index.md',
        method: 'GET',
        evidence: "<form class='navbar-form' action='/search' accept-charset='UTF-8' method='get'>",
      },
    ],
  },
  {
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    priority: 'Low (Medium)',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    parsedDescription:
      ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
  },
];

export const parsedDastNewIssues = [
  {
    alert: 'X-Content-Type-Options Header Missing',
    name: 'X-Content-Type-Options Header Missing',
    riskdesc: 'Low (Medium)',
    priority: 'Low (Medium)',
    desc: '<p>The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff".</p>',
    pluginid: '3456',
    parsedDescription:
      ' The Anti-MIME-Sniffing header X-Content-Type-Options was not set to "nosniff". ',
    instances: [
      {
        uri: 'http://192.168.32.236:3001/assets/webpack/main.bundle.js',
        method: 'GET',
        param: 'X-Content-Type-Options',
      },
    ],
  },
];

/**
 * SAST report API response for no added & fixed issues but with security issues
 */
export const sastHeadAllIssues = [
  {
    tool: 'retire',
    url: 'https://github.com/jquery/jquery/issues/2432',
    file: '/builds/gonzoyumo/test-package-lock/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
    message: '3rd party CORS request may execute',
  },
  {
    tool: 'retire',
    url: 'https://bugs.jquery.com/ticket/11974',
    file: '/builds/gonzoyumo/test-package-lock/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
    message: 'parseHTML() executes scripts in event handlers',
  },
  {
    tool: 'retire',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
    message: 'growl_command-injection',
  },
  {
    tool: 'retire',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
    message: 'growl_command-injection',
  },
];

export const sastBaseAllIssues = [
  {
    tool: 'gemnasium',
    message: 'Command Injection for growl',
    url: 'https://github.com/tj/node-growl/pull/61',
    file: 'package-lock.json',
  },
  {
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for tough-cookie',
    url: 'https://github.com/salesforce/tough-cookie/issues/92',
    file: 'package-lock.json',
  },
  {
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for string',
    url: 'https://github.com/jprichardson/string.js/issues/212',
    file: 'package-lock.json',
  },
  {
    tool: 'gemnasium',
    message: 'Regular Expression Denial of Service for debug',
    url: 'https://nodesecurity.io/advisories/534',
    file: 'package-lock.json',
  },
  {
    tool: 'retire',
    message: '3rd party CORS request may execute',
    url: 'https://github.com/jquery/jquery/issues/2432',
    file: '/code/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
  },
  {
    tool: 'retire',
    message: 'parseHTML() executes scripts in event handlers',
    url: 'https://bugs.jquery.com/ticket/11974',
    file: '/code/node_modules/tinycolor2/demo/jquery-1.9.1.js',
    priority: 'medium',
  },
  {
    tool: 'retire',
    message: 'growl_command-injection',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
  },
  {
    tool: 'retire',
    message: 'growl_command-injection',
    url: 'https://nodesecurity.io/advisories/146',
    priority: 'high',
  },
];
