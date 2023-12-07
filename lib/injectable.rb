require 'injectable/version'
require 'injectable/class_methods'
require 'injectable/dependencies_graph'
require 'injectable/dependencies_proxy'
require 'injectable/dependency'
require 'injectable/instance_methods'
require 'injectable/missing_dependencies_exception'
require 'injectable/method_already_exists_exception'

# Convert your class into an injectable service
#
# @example
#   You would create a service like this:
#
#   class MyPack::Commands::AddPlayerToTeamRoster
#     include Injectable
#
#     dependency :team_repo, class: Repositories::TeamRepo
#     dependency :player_repo, class: Repositories::PlayerRepo
#
#     def call(team_id:, player_id:)
#       team = team_repo.get!(team_id)
#       player = player_repo.get!(player_id)
#
#       team_must_accept_players(team)
#       team_repo.add_to_roster!(team, player)
#     end
#
#     private
#
#     def team_must_accept_players(team)
#       team.accepts_players? || raise Errors::TeamFullError
#     end
#   end
#
#   And use it like this:
#
#   AddPlayerToTeamRoster.call(player_id: "PLAYER_UUID", team_id: "TEAM_UUID")
module Injectable
  def self.included(base)
    base.extend(Injectable::ClassMethods)
    base.prepend(Injectable::InstanceMethods)
  end
end
