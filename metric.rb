#!/usr/bin/env ruby -w
require 'json'
require "awesome_print"

metrics = JSON.parse(File.read(File.expand_path('../db/metrics.json', __FILE__)).force_encoding('UTF-8'))

gamesPlayed = metrics[0]
gameLaucnhed = metrics[1]
uniquePlayers = metrics[2]
waveInfo = metrics[3]

ap "Game launched #{gameLaucnhed}"
ap "Games played: #{gamesPlayed}"
ap "Wave INFO:"
ap waveInfo
ap "\n\n"
ap "Unique players: #{uniquePlayers.size}"
ap "=================="
ap "LIST:"
ap uniquePlayers
