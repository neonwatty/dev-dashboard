module.exports = {
  testEnvironment: "jsdom",
  moduleNameMapper: {
    "^@/(.*)$": "<rootDir>/app/javascript/$1"
  },
  testMatch: [
    "**/test/javascript/**/*.test.js",
    "**/test/javascript/**/*_test.js"
  ],
  setupFilesAfterEnv: ["<rootDir>/test/javascript/setup.js"],
  moduleFileExtensions: ["js", "json"],
  transform: {
    "^.+\\.js$": "babel-jest"
  },
  collectCoverageFrom: [
    "app/javascript/**/*.js",
    "!app/javascript/application.js",
    "!app/javascript/controllers/index.js"
  ],
  coverageDirectory: "coverage/javascript",
  coverageReporters: ["text", "lcov", "html"]
}