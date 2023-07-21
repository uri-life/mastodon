let theLocale;

export function setLocale(locale) {
  theLocale = locale;
}

export function getLocale() {
  return theLocale;
}

export function updateLocale(locale) {
  Object.assign(theLocale.messages, locale.messages);
  if (locale.localeData.length > 0)
    theLocale.localeData = locale.localeData;
}
