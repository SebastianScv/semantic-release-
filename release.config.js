module.exports = {
  branches: ["main"], // or whatever your main branch is called
  plugins: [
    "@semantic-release/commit-analyzer",
    "@semantic-release/release-notes-generator",
    "@semantic-release/npm",
    "@semantic-release/git",
  ],
};
