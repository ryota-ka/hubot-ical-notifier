# Description
#   Notifies schedule for tomorrow from registered iCal calendars
#
# Configuration:
#   ICAL_NOTIFIER_ROOM
#
# Commands:
#   hubot cal:add <url> - Add new iCal calendar
#   hubot cal:list - Show list of registered calendars
#   hubot cal:clear - Clear all of the registered calendars
#
# Author:
#   Ryota Kameoka <kameoka.ryota@gmail.com>

async = require('async')
cron = require('cron').CronJob
ical = require('ical')
moment = require('moment')


config =
  room: process.env.ICAL_NOTIFIER_ROOM


registerJob = (expr, cb) ->
  new cron expr, cb, null, true


getEventsFromICalURL = (url, cb) ->
  ical.fromURL url, {}, (err, data) ->
    return if err

    tomorrow = moment().add(1, 'd')
    events = (data[key] for key of data).map (e) ->
      e.start = moment(e.start)
      e.end = moment(e.end)
      e
    .filter (e) -> e.start.isSame(tomorrow, 'day')

    cb(events)


pl = (n) ->
  if n is 1 then '' else 's'


module.exports = (robot) ->
  getCalendarList = -> robot.brain.get('calendars') || []
  clearCalendarList = -> robot.brain.set('calendars', [])

  registerJob '0 0 21 * * *', ->
    cals = getCalendarList()

    processes = cals.map (cal) ->
      return (cb) ->
        getEventsFromICalURL cal, (events) ->
          cb(null, events)

    async.parallel processes, (err, events) ->
      events = events.reduce (acc, x) ->
        acc.concat x
      , []
      count = events.length

      if count is 0
        robot.send room: config.room, 'You have no scheduled events tomorrow.'
        return

      text = "You have #{count} scheduled event#{pl count} tomorrow.\n"
      text += events.map (e) ->
        location = if e.location then " @#{e.location}" else ''
        start = e.start.format('HH:mm')
        end = e.end.format('HH:mm')
        time = if start is '00:00' and end is '00:00'
          'all day'
        else
          "#{start} - #{end}"
        "#{e.summary}#{location} (#{time})"
      .join "\n"

      robot.send { room: config.channel }, text


  robot.respond /cal:add (.+)/, (msg) ->
    newCal = msg.match[1]
    cals = getCalendarList()
    cals.push newCal
    robot.brain.set 'calendars', cals

    count = cals.length
    text = "New calendar has been added!\n"
    text += "Now you have #{count} calendar#{pl count}."
    msg.send text


  robot.respond /cal:list/, (msg) ->
    cals = getCalendarList()
    count = cals.length
    text =
      if count is 0
        'You have no calendars'
      else
        "You have #{count} calendar#{pl count}."

    msg.send "#{text}\n" + cals.join "\n"


  robot.respond /cal:clear/, (msg) ->
    clearCalendarList()
    msg.send 'All calendars have been cleared.'
