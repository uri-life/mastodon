# frozen_string_literal: true

class TranslationService::GoogleTranslateV2 < TranslationService
  include JsonLdHelper
  
  def initialize(api_key)
    super()

    @api_key  = api_key
  end

  def translate(text, source_language, target_language)
    request(text, source_language, target_language).perform do |res|
      case res.code
      when 403
        raise QuotaExceededError
      when 200...300
        transform_response(res.body_with_limit, source_language)
      else
        raise UnexpectedResponseError
      end
    end
  end

  private

  def request(text, source_language, target_language)
    Request.new(:post, 'https://translation.googleapis.com/language/translate/v2', form: { q: text, source: source_language.presence || '', target: target_language, key: @api_key })
  end

  def transform_response(str, source_language)
    json = Oj.load(str, mode: :strict)

    raise UnexpectedResponseError unless json.is_a?(Hash)

    Translation.new(text: json.dig('data', 'translations', 0, 'translatedText'), detected_source_language: json.dig('data', 'translations', 0, 'detectedSourceLanguage') || source_language, provider: 'Google')
  rescue Oj::ParseError
    raise UnexpectedResponseError
  end
end
