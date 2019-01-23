# Description:
#   Help keep track of whats being ordered for lunch
#
# Dependencies:
#    "cron": "",
#    "time": ""
#
# Configuration:
#   HUBOT_LUNCHBOT_ROOM
#   HUBOT_LUNCHBOT_NOTIFY_AT
#   HUBOT_LUNCHBOT_CLEAR_AT
#   TZ # eg. "America/Los_Angeles"
#
# Notes:
#   nom nom nom
#
# Author:
#   @jpsilvashy
#

##
# What room do you want to post the lunch messages in?
ROOM = process.env.HUBOT_LUNCHBOT_ROOM || 'general'

##
# Set to local timezone
TIMEZONE = process.env.TZ || 'Europe/Berlin' # default timezone

##
# Default lunch notify time
# https://www.npmjs.com/package/node-cron#cron-syntax
NOTIFY_AT = process.env.HUBOT_LUNCHBOT_NOTIFY_AT || '0 0 10 * * 1' # 10 am on Monday, syntax is different from normal cron

##
# clear the lunch order on a schedule
# https://www.npmjs.com/package/node-cron#cron-syntax
CLEAR_AT = process.env.HUBOT_LUNCHBOT_CLEAR_AT || '0 0 20 * * 2' # Evening on Tuesday, syntax is different from normal cron

##
# Exclude from ordering lunch selection
# comma separated list of users to exclude from ordering lunch
EXCLUDE = process.env.HUBOT_LUNCHBOT_EXCLUDE

##
# Lunchday
#
LUNCHDAY = process.env.HUBOT_LUNCHBOT_LUNCHDAY || 'Tuesday'

##
# Restaurants in Salzburg
#
RESTAURANTS = [
  "[Asia Wokman](https://www.lieferservice.at/asia-wok-man)",
  "[De Cesare](http://www.decesare.at/index.php/speisen/aktuelle-angebote)",
  "[Pommes Boutique](http://www.pommes-boutique.com/images/speisekarte_vorne_2016.pdf)",
  "[Crepe Dor](https://www.lieferservice.at/weitere-infos-zu-crpe-dor)",
  "[Way To India](https://www.lieferservice.at/way-to-india)",
  "[Imbiss De Ladi](https://www.lieferservice.at/imbiss-de-ladi)",
  "[Everest](https://www.lieferservice.at/restaurant-everest)",
  "[Risottomas](https://www.risottomas.at/speisekarte/)",
  "[Sa Thai Küche](https://sasthaikueche.jimdofree.com/men%C3%BC/)"
]

##
# setup cron
CronJob = require("cron").CronJob

shuffle = (array) ->
  for index in [array.length-1..1]
    randomIndex = Math.floor Math.random() * (index + 1)
    [array[index], array[randomIndex]] = [array[randomIndex], array[index]]
  array

module.exports = (robot) ->

  # Make sure the lunch dictionary exists
  robot.brain.data.lunch = robot.brain.data.lunch || {}

  # Explain how to use the lunch bot
  MESSAGE = """
  Let's order lunch for *#{LUNCHDAY}* by using the cool bot! You can say:
  #{robot.name} I want BLT Sandwich - adds "BLT Sandwich" to the list of items to be ordered
  #{robot.name} @user wants Pizza - adds "Pizza" to the list of items to be ordered for @user
  #{robot.name} restaurants - shows a shuffled list of restaurants
  #{robot.name} remove my order - removes your order
  #{robot.name} cancel all orders - cancels all the orders
  #{robot.name} lunch orders - lists all orders
  #{robot.name} who should order|pickup|get lunch? - randomly selects person to either order or pickup lunch
  #{robot.name} lunch help - displays this help message
  """

  ##
  # Define the lunch functions
  lunch =
    get: ->
      Object.keys(robot.brain.data.lunch)

    add: (user, item) ->
      robot.brain.data.lunch[user] = item

    remove: (user) ->
      delete robot.brain.data.lunch[user]

    clear: ->
      robot.brain.data.lunch = {}
      robot.messageRoom ROOM, "lunch order cleared..."

    notify: ->
      robot.messageRoom ROOM, MESSAGE

  ##
  # Define things to be scheduled
  schedule =
    notify: (time) ->
      new CronJob(time, ->
        lunch.notify()
        return
      , null, true, TIMEZONE)

    clear: (time) ->
      new CronJob(time, ->
        robot.brain.data.lunch = {}
        return
      , null, true, TIMEZONE)

  ##
  # Schedule when to alert the ROOM that it's time to start ordering lunch
  schedule.notify NOTIFY_AT

  ##
  # Schedule when the order should be cleared at
  schedule.clear CLEAR_AT

  ##
  # List out all the orders
  robot.respond /lunch orders$/i, (msg) ->
    orders = lunch.get().map (user) -> "#{user}: #{robot.brain.data.lunch[user]}"
    msg.send orders.join("\n") || "No items in the lunch list."

  ##
  # Save what a person wants to the lunch order
  robot.respond /i want (.*)/i, (msg) ->
    item = msg.match[1].trim()
    lunch.add msg.message.user.name, item
    msg.send "ok, added #{item} to your order."

  robot.respond /@(.*) wants (.*)/i, (msg) ->
    user = msg.match[1].trim()
    item = msg.match[2].trim()
    lunch.add user, item
    msg.send "ok, added #{item} to @#{user} order."

  robot.respond /restaurants/i, (msg) ->
    msg.send ":fork_knife_plate: Restaurants: " + shuffle(RESTAURANTS).join(", ")

  ##
  # Remove the persons items from the lunch order
  robot.respond /remove my order/i, (msg) ->
    lunch.remove msg.message.user.name
    msg.send "ok, I removed your order."

  ##
  # Cancel the entire order and remove all the items
  robot.respond /cancel all orders/i, (msg) ->
    delete robot.brain.data.lunch
    lunch.clear()

  ##
  # Help decided who should either order, pickup or get
  robot.respond /who should (order|pickup|get) lunch?/i, (msg) ->
    orders = lunch.get().map (user) -> user
    excluded = EXCLUDE.split(',')
    filtered = orders.filter (user) -> excluded.indexOf(user) is -1

    key = Math.floor(Math.random() * filtered.length)

    if filtered[key]?
      msg.send "@#{filtered[key]} looks like you have to #{msg.match[1]} lunch today!"
    else
      msg.send "Hmm... Looks like no one has ordered any lunch yet today."

  ##
  # Display usage details
  robot.respond /lunch help/i, (msg) ->
    msg.send MESSAGE

  ##
  # Just print out the details on how the lunch bot is configured
  robot.respond /lunch config/i, (msg) ->
    msg.send "ROOM: #{ROOM} \nTIMEZONE: #{TIMEZONE} \nNOTIFY_AT: #{NOTIFY_AT} \nCLEAR_AT: #{CLEAR_AT}\nEXCLUDE: #{EXCLUDE}\nLUNCHDAY: #{LUNCHDAY}\n  "
