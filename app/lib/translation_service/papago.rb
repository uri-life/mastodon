# frozen_string_literal: true

class TranslationService::Papago < TranslationService
  include JsonLdHelper

  def initialize(api_key_id, api_key_secret)
    super()

    @api_key_id = api_key_id
    @api_key_secret = api_key_secret
  end

  def translate(texts, source_language, target_language)
    texts.map do |text|
      form = { source: source_language.presence, target: target_language, text: text }

      if text.empty?
        Translation.new(
          text: text,
          detected_source_language: source_language,
          provider: provider
        )
      else
        request(:post, '/nmt/v1/translation', form: form) do |res|
          transform_response(res.body_with_limit, source_language)
        end
      end
    end
  end

  def languages
    supported_languages = {
      'ko' => %w(en ja zh-CN zh-TW vi th id fr es ru de it),
      'en' => %w(ja zh-CN zh-TW vi th id fr),
      'ja' => %w(zh-CN zh-TW vi th id fr),
      'zh-CN' => %w(zh-TW),
    }

    inverse_mapping = {}
    supported_languages.each do |key, values|
      values.each do |value|
        inverse_mapping[value] ||= []
        inverse_mapping[value] << key unless inverse_mapping[value].include?(key)
      end
    end

    supported_languages.merge(inverse_mapping) do |_, lhs, rhs|
      (lhs + rhs).uniq
    end
  end

  private

  def request(verb, path, **options)
    req = Request.new(verb, "#{base_url}#{path}", **options)
    req.add_headers('Content-Type': 'application/x-www-form-urlencoded', 'X-Ncp-Apigw-Api-Key-Id': @api_key_id, 'X-Ncp-Apigw-Api-Key': @api_key_secret)
    req.perform do |res|
      case res.code
      when 429
        json = Oj.load(res.body_with_limit, mode: :strict)
        raise UnexpectedResponseError unless json.is_a?(Hash)

        case json.dig('error', 'errorCode')
        when '400'
          raise QuotaExceededError
        else
          raise TooManyRequestsError
        end
      when 200...300
        yield res
      else
        raise UnexpectedResponseError
      end
    end
  rescue Oj::ParseError
    raise UnexpectedResponseError
  end

  def base_url
    'https://naveropenapi.apigw.ntruss.com'
  end

  def provider
    'Papago'
  end

  def transform_response(json, source_language)
    data = Oj.load(json, mode: :strict)
    raise UnexpectedResponseError unless data.is_a?(Hash)

    Translation.new(
      text: Sanitize.fragment(data.dig('message', 'result', 'translatedText'), Sanitize::Config::MASTODON_STRICT),
      detected_source_language: data.dig('message', 'result', 'srcLangType') || source_language,
      provider: 'Papago'
    )
  rescue Oj::ParseError
    raise UnexpectedResponseError
  end
end
