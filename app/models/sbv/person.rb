#  Copyright (c) 2012-2019, Schweizer Blasmusikverband. This file is part of
#  hitobito_sbv and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sbv.

module Sbv::Person
  extend ActiveSupport::Concern

  included do
    Person::PUBLIC_ATTRS << :correspondence_language << :personal_data_usage
    Person::FILTER_ATTRS << :active_years << [:prognostic_active_years, :integer]

    validates :first_name, :last_name, :birthday, presence: true

    # validates :correspondence_language,
    #           inclusion: { in: lambda do |_|
    #                              Settings.application.languages.to_hash.keys.collect(&:to_s)
    #                            end,
    #                        allow_blank: true }

  end

  def prognostic_active_years
    if active_role?
      active_years.succ
    else
      active_years
    end
  end

  def update_active_years
    cache_active_years
    save(validate: false)
  end

  def cache_active_years
    self.active_role = active_member_role?
    self.active_years = calculate_active_years
  end

  private

  def active_member_role?
    roles.where("type LIKE '%Mitglied'").any?
  end

  def calculate_active_years(end_date = Time.zone.now)
    roles.with_deleted.where("type LIKE '%Mitglied'").map do |role|
      VeteranYears.new(role.created_at.year, (role.deleted_at || end_date).year)
    end.sort.sum.years.to_i
  end

end
