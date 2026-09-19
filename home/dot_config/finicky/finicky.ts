import type {
  BrowserHandler,
  FinickyConfig,
} from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

const BROWSERS = {
  SAFARI: "Safari",
  CHROME: "Google Chrome",
} as const;

const CHROME_HOSTS = [
  "whereby.com",
  "meet.google.com",
  "youtube.com",
  "youtu.be",
  "teams.microsoft.com",
];

const matchesHost = (url: URL, host: string): boolean =>
  url.host === host || url.host.endsWith(`.${host}`);

const routeToChrome: BrowserHandler = {
  match: (url) => CHROME_HOSTS.some((host) => matchesHost(url, host)),
  browser: BROWSERS.CHROME,
};

export default {
  defaultBrowser: BROWSERS.SAFARI,
  options: {
    checkForUpdates: false,
  },
  handlers: [routeToChrome],
} satisfies FinickyConfig;
