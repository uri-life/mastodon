const HASHTAG_SEPARATORS = '_\\u00b7\\u200c';
const WORD = '\\p{L}\\p{M}\\p{N}\\p{Pc}';

const buildHashtagPatternRegex = () => {
  try {
    return new RegExp(
      `(?:^|[^\\/\\)\\w])#(([${WORD}_][${WORD}${HASHTAG_SEPARATORS}]*[${WORD}_])|([${WORD}_]*))`,
      'iu',
    );
  } catch {
    return /(?:^|[^/)\w])#([\w0-9]*[a-zA-Z0-9·][\w0-9]*)/i;
  }
};

const buildHashtagRegex = () => {
  try {
    return new RegExp(
      `^(([${WORD}_][${WORD}${HASHTAG_SEPARATORS}]*[${WORD}_])|([${WORD}_]*))$`,
      'iu',
    );
  } catch {
    return /^([\w0-9]*[a-zA-Z0-9·][\w0-9]*)$/i;
  }
};

export const HASHTAG_PATTERN_REGEX = buildHashtagPatternRegex();

export const HASHTAG_REGEX = buildHashtagRegex();
