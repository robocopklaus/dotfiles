const BROWSERS = {
  SAFARI: "Safari",
  CHROME: "Google Chrome"
};

const MATCH_PATTERNS = [
  "whereby.com/*",
  "meet.google.com/*",
  "*.youtube.com/*",
  "youtu.be/*",
  "teams.microsoft.com/*"
];

module.exports = {
  defaultBrowser: BROWSERS.SAFARI,
  options: {
    hideIcon: true,
  },
  handlers: [
    {
      match: MATCH_PATTERNS,
      browser: BROWSERS.CHROME
    }
  ]
};
