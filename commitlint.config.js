module.exports = {
  extends: ["@commitlint/config-conventional"],
  rules: {
    "type-enum": [2, "always", ["feat", "fix", "chore"]],
    "scope-case": [2, "always", "upper-case"],
    "scope-pattern": [2, "always", "^DIJ-\\d+$"],
    "subject-empty": [2, "never"],
    "subject-full-stop": [2, "never", "."],
    "header-max-length": [2, "always", 72],
  },
};
