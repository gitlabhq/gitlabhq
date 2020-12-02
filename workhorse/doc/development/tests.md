# Testing your code

Run the tests with:

```
make clean test
```

## Coverage / what to test

Each feature in GitLab Workhorse should have an integration test that
verifies that the feature 'kicks in' on the right requests and leaves
other requests unaffected. It is better to also have package-level tests
for specific behavior but the high-level integration tests should have
the first priority during development.

It is OK if a feature is only covered by integration tests.
