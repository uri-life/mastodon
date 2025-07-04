# frozen_string_literal: true

class StatusReactionValidator < ActiveModel::Validator
  SUPPORTED_EMOJIS = Oj.load_file(Rails.root.join('app', 'javascript', 'mastodon', 'features', 'emoji', 'emoji_map.json').to_s).keys.freeze

  def validate(reaction)
    return if reaction.name.blank?

    reaction.errors.add(:name, I18n.t('reactions.errors.unrecognized_emoji')) if reaction.custom_emoji_id.blank? && !unicode_emoji?(reaction.name)
  end

  private

  def unicode_emoji?(name)
    SUPPORTED_EMOJIS.include?(name)
  end

  def new_reaction?(reaction)
    !reaction.status.status_reactions.exists?(status: reaction.status, account: reaction.account, name: reaction.name, custom_emoji: reaction.custom_emoji)
  end
end
