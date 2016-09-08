somata = require 'somata'
redis = require('redis').createClient()
request = require 'request'

findPoints = (cb) ->
    redis.hvals 'centerpoint:points', (err, point_jsons=[]) ->
        if err?
            somata.log.e err.toString()
        points = point_jsons.map (point_json) -> JSON.parse point_json
        console.log '[findPoints]', points.length
        cb null, points

createPoint = (point, cb) ->
    console.log '[createPoint]', point
    geocode point.address, (err, position) ->
        if position
            point.position = position
            point_json = JSON.stringify point
            redis.hset 'centerpoint:points', point.name, point_json, (err) ->
                cb err, point

        else
            cb null, point

removePoint = (name, cb) ->
    redis.hdel 'centerpoint:points', name, cb

geocode_key = 'AIzaSyAJp6oACbrVBZwWszMLrZLSAgt4IdjlX04'

geocodeUrl = (address) ->
    "https://maps.googleapis.com/maps/api/geocode/json?address=#{encodeURIComponent address}&sensor=false&key=#{geocode_key}"# +

geocode = (address, cb) ->
    console.log '[geocode]', address
    request.get
        url: geocodeUrl(address)
        json: true

    , (err, res, data) ->
        return cb err if err?

        if result = data.results[0]
            {lat, lng} = result.geometry.location
            cb null, {lat, lng}
        else
            cb null

new somata.Service 'centerpoint', {
    findPoints
    createPoint
    removePoint
}
