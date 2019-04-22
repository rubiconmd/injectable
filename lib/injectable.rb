require 'injectable/version'
require 'injectable/class_methods'
require 'injectable/dependencies_graph'
require 'injectable/dependencies_proxy'
require 'injectable/dependency'
require 'injectable/instance_methods'
require 'injectable/missing_dependencies_exception'

# Convert your class into an injectable service
#
# @example
#   You would create a service like this:
#
#   class AddPlayerToTeamRoster
#     include Injectable
#
#     dependency :team_query
#     dependency :player_query, class: UserQuery
#
#     argument :team_id
#     argument :player_id
#
#     def call
#       player_must_exist!
#       team_must_exist!
#       team_must_accept_players!
#
#       team.add_to_roster(player)
#     end
#
#     private
#
#     def player
#       @player ||= player_query.call(player_id)
#     end
#
#     def team
#       @team ||= team_query.call(team_id)
#     end
#
#     def player_must_exist!
#       player.present? || raise UserNotFoundException
#     end
#
#     def team_must_exist!
#       team.present? || raise TeamNotFoundException
#     end
#
#     def team_must_accept_players!
#       team.accepts_players? || raise TeamFullException
#     end
#   end
#
#   And use it like this:
#
#   AddPlayerToTeamRoster.call(player_id: player.id, team_id: team.id)
module Injectable
  def self.included(base)
    base.extend(Injectable::ClassMethods)
    base.prepend(Injectable::InstanceMethods)
  end
end
