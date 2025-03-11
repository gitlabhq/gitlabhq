module.exports = {
  roots: [
    "<rootDir>/src"
  ],
  verbose: true,
  testMatch: [
    "**/__tests__/**/[^.]+Test.ts",
  ],
  transform: {
    "^.+\\.ts$": "ts-jest"
  },
}
