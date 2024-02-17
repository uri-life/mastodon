# frozen_string_literal: true

module AccountFinderConcern
  extend ActiveSupport::Concern

  class_methods do
    def find_local!(username)
      find_local(username) || raise(ActiveRecord::RecordNotFound)
    end

    def find_remote!(username, domain)
      find_remote(username, domain) || raise(ActiveRecord::RecordNotFound)
    end

    def find_remote_any!(domain)
      find_remote_any(nil, domain) || raise(ActiveRecord::RecordNotFound)
    end

    def representative
      actor = Account.find(-99).tap(&:ensure_keys!)
      actor.update!(username: 'mastodon.internal') if actor.username.include?(':')
      actor
    rescue ActiveRecord::RecordNotFound
      Account.create!(id: -99, actor_type: 'Application', locked: true, username: 'mastodon.internal')
    end

    def find_local(username)
      find_remote(username, nil)
    end

    def find_remote(username, domain)
      AccountFinder.new(username, domain).account
    end

    def find_remote_any(domain)
      finder = AccountFinder.new(nil, domain)
      finder.set_find_any_user
      finder.account
    end
  end

  class AccountFinder
    attr_reader :username, :domain

    def initialize(username, domain)
      @username = username
      @domain = domain
      @should_find_any_user = false
    end

    def account
      scoped_accounts.order(id: :asc).take
    end

    def set_find_any_user
      @should_find_any_user = true
    end

    private

    def scoped_accounts
      Account.unscoped.tap do |scope|
        unless @should_find_any_user
          scope.merge! with_usernames
          scope.merge! matching_username
        end
        scope.merge! matching_domain
      end
    end

    def with_usernames
      Account.where.not(Account.arel_table[:username].lower.eq '')
    end

    def matching_username
      Account.where(Account.arel_table[:username].lower.eq username.to_s.downcase)
    end

    def matching_domain
      Account.where(Account.arel_table[:domain].lower.eq(domain.nil? ? nil : domain.to_s.downcase))
    end
  end
end
