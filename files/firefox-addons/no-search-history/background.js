// Match google.com, google.ch, google.co.uk, google.com.au, mail.google.com...
const hosts = /(^|\.)(google|kagi|startpage|duckduckgo)\.(com?\.)?[a-z]+$/;

browser.history.onVisited.addListener(({ url }) => {
  let hostname;
  try {
    hostname = new URL(url).hostname;
  } catch {
    return;
  }
  if (hosts.test(hostname)) {
    browser.history.deleteUrl({ url });
  }
});
